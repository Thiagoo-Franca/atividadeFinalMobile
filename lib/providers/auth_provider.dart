import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;
  User? _user;
  late final AppLinks _appLinks;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  AuthProvider() {
    if (!kIsWeb) {
      _appLinks = AppLinks();
      _initDeepLinks();
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      _isAuthenticated = session != null;
      _user = session?.user;

      if (session != null) {
        print('User signed in: ${_user?.email}');
        await _ensureExists(session.user);
      }
      _isLoading = false;
      notifyListeners();
    });

    _checkInitialSession();
  }
  Future<void> _checkInitialSession() async {
    try {
      print('Checking initial session...');
      final session = Supabase.instance.client.auth.currentSession;

      _isAuthenticated = session != null;
      _user = session?.user;

      if (session != null) {
        print('Active session found for: ${_user?.email}');
        await _ensureUserExists(session.user);
      } else {
        print('No active session found');
      }
    } catch (e) {
      print('Error checking initial session: $e');
      _error = 'Erro ao verificar sessão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureUserExists(User authUser) async {
    try {
      final response = await Supabase.instance.client
          .from('user')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (response == null) {
        print('Creating user record for ${authUser.email}');
        await Supabase.instance.client.from('user').insert({
          'id': authUser.id,
          'email': authUser.email,
          'name':
              authUser.userMetadata?['full_name'] ??
              authUser.userMetadata?['name'] ??
              authUser.email?.split('@')[0] ??
              'Usuario',
        });
        print('User record created successfully');
      } else {
        print('User record already exists');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
      _error = 'Erro ao verificar usuário: $e';
    }
  }

  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      print('Received deep link: $uri');
      if (uri != null) {
        print('Deep link received: $uri');
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'myapp' && uri.host == 'login-callback') {
      print('OAuth callback detected');
    }
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      _isAuthenticated = session != null;
      _user = session?.user;
      print('Session check - authenticated: $_isAuthenticated');
    } catch (e) {
      _error = 'Erro ao verificar status de autenticação: $e';
      print('Error checking auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureExists(User authUser) async {
    try {
      final response = await Supabase.instance.client
          .from('user')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (response == null) {
        print('Creating user record for ${authUser.email}');
        await Supabase.instance.client.from('user').insert({
          'id': authUser.id,
          'email': authUser.email,
          'name':
              authUser.userMetadata?['name'] ??
              authUser.email?.split('@')[0] ??
              'Usuario',
        });
        print('User record created for ${authUser.email}');
      } else {
        print('User record already exists for ${authUser.email}');
      }
    } catch (e) {
      print('Error ensuring user exists: $e');
      _error = 'Erro ao garantir existência do usuário: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Iniciando login com Google...');

      if (kIsWeb) {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
      } else {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'myapp://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }

      print('OAuth initiated successfully');
      return true;
    } catch (e) {
      _error = 'Erro ao fazer login com Google: $e';
      print('Erro no login com Google: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out...');

      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);

      _isAuthenticated = false;
      _user = null;
      _error = null;

      print('Sign out successful');
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao fazer logout: $e';
      print('Sign out error: $e');
      notifyListeners();
    }
  }
}
