import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth/auth_bloc.dart';
import 'auth/auth_event.dart';
import 'auth/auth_state.dart';
import 'auth/login_layar.dart';
import 'barang/barang_layar.dart';
import 'beranda/admin_drawer.dart';
import 'beranda/beranda_layar.dart';
import 'pelanggan/pelanggan_layar.dart';
import 'setoran/setoran_screen.dart';
import 'tema.dart';

class AppAdmin extends StatelessWidget {
  const AppAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc()..add(CekSesi()),
      child: MaterialApp(
        title: 'Obos Admin',
        debugShowCheckedModeBanner: false,
        theme: Tema.terang(),
        onGenerateRoute: (settings) {
          final halaman = switch (settings.name) {
            '/barang' => HalamanAdmin.barang,
            '/pelanggan' => HalamanAdmin.pelanggan,
            '/setoran' => HalamanAdmin.setoran,
            _ => HalamanAdmin.beranda,
          };
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _Gerbang(halaman: halaman),
          );
        },
      ),
    );
  }
}

class _Gerbang extends StatelessWidget {
  const _Gerbang({this.halaman = HalamanAdmin.beranda});

  final HalamanAdmin halaman;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthMasuk) {
          if (halaman == HalamanAdmin.barang) {
            return const BarangLayar();
          }
          if (halaman == HalamanAdmin.pelanggan) {
            return const PelangganLayar();
          }
          if (halaman == HalamanAdmin.setoran) {
            return const SetoranScreen();
          }
          return BerandaLayar(nama: state.nama, email: state.email);
        }
        return Stack(
          children: [
            LoginLayar(
              pesan: state is AuthKeluar ? state.pesan : null,
            ),
            if (state is! AuthKeluar)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}
