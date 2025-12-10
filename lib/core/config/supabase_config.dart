import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://douwctlommhpagyfdanb.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvdXdjdGxvbW1ocGFneWZkYW5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwOTA0NzAsImV4cCI6MjA3OTY2NjQ3MH0.MOQddEYhLsaNgGc7tkdokMlQqL9olI0hV-qJsnBBwCs';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://douwctlommhpagyfdanb.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRvdXdjdGxvbW1ocGFneWZkYW5iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwOTA0NzAsImV4cCI6MjA3OTY2NjQ3MH0.MOQddEYhLsaNgGc7tkdokMlQqL9olI0hV-qJsnBBwCs',
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
