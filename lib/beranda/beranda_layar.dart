import 'package:flutter/material.dart';

import '../tema.dart';
import 'admin_drawer.dart';

class BerandaLayar extends StatelessWidget {
  const BerandaLayar({super.key, required this.nama, required this.email});

  final String nama;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarAdmin('Obos Admin'),
      drawer: const AdminDrawer(halaman: HalamanAdmin.beranda),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pad = constraints.maxHeight < 160 ? 12.0 : 24.0;
          final minTinggi = (constraints.maxHeight - pad * 2).clamp(
            0.0,
            double.infinity,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minTinggi,
                maxWidth: 520,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nama,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Tema.seed,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buka menu di kiri untuk Barang, Pelanggan, Setoran, dan halaman lain.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
