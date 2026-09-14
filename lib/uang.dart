import 'package:flutter/services.dart';

class Uang {
  static const _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static int dari(Object? v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static String angka(Object? nominal) {
    return dari(nominal).toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  static int angkaTeks(String s) {
    final digits = s.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static String hariTanggal(DateTime d) {
    return '${_hari[d.weekday - 1]} ${d.day}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  static String pendek(DateTime d) {
    return '${d.day}/${d.month.toString().padLeft(2, '0')}';
  }

  static String rp(int nominal) => 'Rp ${angka(nominal)}';

  static String tanggal(DateTime d) {
    final h = d.day.toString().padLeft(2, '0');
    final b = d.month.toString().padLeft(2, '0');
    return '$h/$b/${d.year}';
  }

  static String jam(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  static String tanggalJam(DateTime d) => '${tanggal(d)} ${jam(d)}';

  static String isoHari(DateTime d) {
    final h = d.day.toString().padLeft(2, '0');
    final b = d.month.toString().padLeft(2, '0');
    return '${d.year}-$b-$h';
  }
}

class UangFormatRibuan extends TextInputFormatter {
  const UangFormatRibuan({this.kosong = '0'});

  final String kosong;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return TextEditingValue(
        text: kosong,
        selection: TextSelection.collapsed(offset: kosong.length),
      );
    }
    final teks = Uang.angka(int.parse(digits));
    return TextEditingValue(
      text: teks,
      selection: TextSelection.collapsed(offset: teks.length),
    );
  }
}
