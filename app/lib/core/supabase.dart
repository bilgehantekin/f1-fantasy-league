import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(url: Env.supabaseUrl, anonKey: Env.supabaseAnonKey);
}

SupabaseClient get supabase => Supabase.instance.client;

final supabaseProvider = Provider<SupabaseClient>((_) => supabase);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabase.auth.onAuthStateChange;
});

final currentSessionProvider = Provider<Session?>((ref) {
  final state = ref.watch(authStateProvider).asData?.value;
  return state?.session ?? supabase.auth.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(currentSessionProvider)?.user;
});
