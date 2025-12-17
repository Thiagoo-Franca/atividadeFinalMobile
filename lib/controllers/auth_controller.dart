import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import '../repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;
  User? _user;
  late final AppLinks _appLinks;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  AuthController(this._repository) {
    if (!kIsWeb) {
      _appLinks = AppLinks();
      _initDeepLinks();
    }

    _repository.onAuthStateChange.listen((data) async {
      final session = data.session;
      _isAuthenticated = session != null;
      _user = session?.user;

      if (session != null) {
        await _ensureUserExists(session.user);
      }

      _isLoading = false;
      notifyListeners();
    });

    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    try {
      final session = _repository.currentSession;

      _isAuthenticated = session != null;
      _user = session?.user;

      if (session != null) {
        await _ensureUserExists(session.user);
      }
    } catch (e) {
      _error = 'Erro ao verificar sessão: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _initDeepLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'myapp' && uri.host == 'login-callback') {}
  }

  Future<void> _ensureUserExists(User authUser) async {
    try {
      final existingUser = await _repository.getUserById(authUser.id);

      if (existingUser == null) {
        final name =
            authUser.userMetadata?['full_name'] ??
            authUser.userMetadata?['name'] ??
            authUser.email?.split('@')[0] ??
            'Usuário';

        await _repository.createUser(
          id: authUser.id,
          email: authUser.email ?? '',
          name: name,
        );
      }
    } catch (e) {
      _error = 'Erro ao verificar usuário: $e';
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kIsWeb) {
        await _repository.signInWithGoogle(redirectTo: Uri.base.origin);
      } else {
        await _repository.signInWithGoogle(
          redirectTo: 'myapp://login-callback',
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }

      return true;
    } catch (e) {
      _error = 'Erro ao fazer login com Google: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.signOut();

      _isAuthenticated = false;
      _user = null;
      _error = null;
    } catch (e) {
      _error = 'Erro ao fazer logout: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
