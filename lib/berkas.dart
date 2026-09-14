import 'berkas_io.dart'
    if (dart.library.js_interop) 'berkas_web.dart'
    if (dart.library.html) 'berkas_web.dart' as impl;

class Berkas {
  static Future<bool> unduhCsv(String nama, String isi) =>
      impl.unduhCsv(nama, isi);

  static Future<String?> pilihCsv() => impl.pilihCsv();
}
