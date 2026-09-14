import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_bloc.dart';
import '../auth/auth_event.dart';
import '../auth/auth_state.dart';
import '../tema.dart';

enum HalamanAdmin { beranda, barang, pelanggan, setoran }

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key, required this.halaman});

  final HalamanAdmin halaman;

  void _tutup(BuildContext context) {
    Navigator.pop(context);
  }

  void _keBeranda(BuildContext context) {
    final nav = Navigator.of(context);
    _tutup(context);
    if (halaman == HalamanAdmin.beranda) return;
    nav.pushNamedAndRemoveUntil('/', (r) => false);
  }

  void _keBarang(BuildContext context) {
    final nav = Navigator.of(context);
    _tutup(context);
    if (halaman == HalamanAdmin.barang) return;
    nav.pushNamedAndRemoveUntil('/barang', (r) => false);
  }

  void _kePelanggan(BuildContext context) {
    final nav = Navigator.of(context);
    _tutup(context);
    if (halaman == HalamanAdmin.pelanggan) return;
    nav.pushNamedAndRemoveUntil('/pelanggan', (r) => false);
  }

  void _keSetoran(BuildContext context) {
    final nav = Navigator.of(context);
    _tutup(context);
    if (halaman == HalamanAdmin.setoran) return;
    nav.pushNamedAndRemoveUntil('/setoran', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final nama = auth is AuthMasuk ? auth.nama : '';
    final email = auth is AuthMasuk ? auth.email : '';

    return Drawer(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: ColoredBox(
              color: Tema.biru,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Text(
                    'Obos Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 13, color: Tema.redup),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider()),
          SliverList.list(
            children: [
              _item(
                ikon: Icons.home_outlined,
                judul: 'Beranda',
                pilih: halaman == HalamanAdmin.beranda,
                onTap: () => _keBeranda(context),
              ),
              _item(
                ikon: Icons.inventory_2_outlined,
                judul: 'Barang',
                pilih: halaman == HalamanAdmin.barang,
                onTap: () => _keBarang(context),
              ),
              _item(
                ikon: Icons.storefront_outlined,
                judul: 'Pelanggan',
                pilih: halaman == HalamanAdmin.pelanggan,
                onTap: () => _kePelanggan(context),
              ),
              _item(
                ikon: Icons.payments_outlined,
                judul: 'Setoran',
                pilih: halaman == HalamanAdmin.setoran,
                onTap: () => _keSetoran(context),
              ),
            ],
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_outlined,
                      color: Colors.red,
                    ),
                    title: const Text(
                      'Keluar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      _tutup(context);
                      context.read<AuthBloc>().add(MintaKeluar());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required IconData ikon,
    required String judul,
    required bool pilih,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(ikon, color: Tema.biru),
      title: Text(
        judul,
        style: TextStyle(
          fontWeight: pilih ? FontWeight.bold : FontWeight.w600,
          color: pilih ? Tema.seed : Colors.black87,
        ),
      ),
      selected: pilih,
      selectedTileColor: const Color(0xFFD6E8F7),
      onTap: onTap,
    );
  }
}

PreferredSizeWidget appBarAdmin(String judul) {
  return AppBar(
    title: Text(judul),
    leading: Builder(
      builder: (ctx) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(ctx).openDrawer(),
      ),
    ),
  );
}
