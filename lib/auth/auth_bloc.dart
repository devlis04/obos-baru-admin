import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../umpan.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthAwal()) {
    on<CekSesi>(_onCek);
    on<MintaMasuk>(_onMasuk);
    on<MintaKeluar>(_onKeluar);
  }

  final _sb = Supabase.instance.client;

  Future<Map<String, dynamic>?> _profil() async {
    final hasil = await _sb.rpc('admin_profil').timeout(const Duration(seconds: 12));
    if (hasil is List && hasil.isNotEmpty && hasil.first is Map) {
      return Map<String, dynamic>.from(hasil.first as Map);
    }
    if (hasil is Map) {
      return Map<String, dynamic>.from(hasil);
    }
    return null;
  }

  Future<void> _onCek(CekSesi event, Emitter<AuthState> emit) async {
    emit(AuthMemuat());
    final sesi = _sb.auth.currentSession;
    if (sesi == null) {
      emit(AuthKeluar());
      return;
    }
    try {
      await _sb.auth.refreshSession();
    } catch (_) {}
    try {
      final profil = await _profil();
      final nama = profil?['nama']?.toString().trim();
      final email = profil?['email']?.toString().trim();
      if (nama == null || nama.isEmpty || email == null || email.isEmpty) {
        try {
          await _sb.auth.signOut();
        } catch (_) {}
        emit(AuthKeluar());
        return;
      }
      emit(AuthMasuk(nama: nama, email: email));
    } catch (e) {
      try {
        await _sb.auth.signOut();
      } catch (_) {}
      emit(
        AuthKeluar(
          pesan: pesanGagal(e, 'Sesi tidak aktif. Masuk lagi.'),
        ),
      );
    }
  }

  Future<void> _onMasuk(MintaMasuk event, Emitter<AuthState> emit) async {
    emit(AuthMemuat());
    try {
      final res = await _sb.auth.signInWithPassword(
        email: event.email.trim(),
        password: event.sandi,
      );
      if (res.user?.email == null) {
        emit(AuthKeluar(pesan: 'Email atau kata sandi tidak sesuai.'));
        return;
      }
      final profil = await _profil();
      final nama = profil?['nama']?.toString().trim();
      final email = profil?['email']?.toString().trim();
      if (nama == null || nama.isEmpty || email == null || email.isEmpty) {
        try {
          await _sb.auth.signOut();
        } catch (_) {}
        emit(
          AuthKeluar(pesan: 'Hanya akun admin yang boleh masuk web ini.'),
        );
        return;
      }
      emit(AuthMasuk(nama: nama, email: email));
    } on AuthException catch (e) {
      emit(AuthKeluar(pesan: _pesanMasuk(e.message)));
    } catch (e) {
      try {
        await _sb.auth.signOut();
      } catch (_) {}
      emit(
        AuthKeluar(
          pesan: pesanGagal(
            e,
            'Tidak bisa masuk. Periksa internet, lalu coba lagi.',
          ),
        ),
      );
    }
  }

  Future<void> _onKeluar(MintaKeluar event, Emitter<AuthState> emit) async {
    emit(AuthMemuat());
    try {
      await _sb.auth.signOut();
    } catch (_) {}
    emit(AuthKeluar());
  }

  String _pesanMasuk(String asli) {
    final t = asli.toLowerCase();
    if (t.contains('invalid') ||
        t.contains('credential') ||
        t.contains('password')) {
      return 'Email atau kata sandi tidak sesuai.';
    }
    return 'Tidak bisa masuk. Periksa email, sandi, dan internet.';
  }
}
