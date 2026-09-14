abstract class AuthState {}

class AuthAwal extends AuthState {}

class AuthMemuat extends AuthState {}

class AuthMasuk extends AuthState {
  AuthMasuk({required this.nama, required this.email, this.info});
  final String nama;
  final String email;
  final String? info;
}

class AuthKeluar extends AuthState {
  AuthKeluar({this.pesan});
  final String? pesan;
}
