import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NadaUmpan { merah, hijau, kuning }

void umpan(
  BuildContext context,
  String pesan, {
  NadaUmpan nada = NadaUmpan.merah,
}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final kuning = nada == NadaUmpan.kuning;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: switch (nada) {
        NadaUmpan.merah => Colors.red,
        NadaUmpan.hijau => Colors.green,
        NadaUmpan.kuning => const Color(0xFFF9A825),
      },
      content: Text(
        pesan,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: kuning ? Colors.black : Colors.white,
        ),
      ),
    ),
  );
}

String pesanGagal(Object e, String cadangan) {
  if (e is PostgrestException && e.message.trim().isNotEmpty) {
    return e.message.trim();
  }
  final t = e.toString();
  if (t.contains('Hanya akun admin')) {
    return 'Hanya akun admin yang boleh masuk web ini.';
  }
  return cadangan;
}
