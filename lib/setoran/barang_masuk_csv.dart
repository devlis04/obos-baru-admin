import 'dart:convert';
import 'dart:typed_data';

class BarisMasukCsv {
  final String kode;
  final String nama;
  final int qty;
  final int harga;
  final bool baru;
  final String satuan;
  final String rincian;
  final String kategori;

  const BarisMasukCsv({
    required this.kode,
    required this.nama,
    required this.qty,
    required this.harga,
    this.baru = false,
    this.satuan = '',
    this.rincian = '',
    this.kategori = '',
  });
}

class HasilMasukCsv {
  final List<BarisMasukCsv> baris;
  final String? error;

  const HasilMasukCsv(this.baris, [this.error]);
}

class BarangMasukCsv {
  static const namaBerkas = 'barang_masuk.csv';

  static const template =
      'kode_barang;nama_barang;qty;harga_beli\r\n';

  static Uint8List bytesTemplate([
    List<({String kode, String nama})> katalog = const [],
  ]) {
    final buf = StringBuffer()
      ..write('\uFEFF')
      ..write(template);
    for (final b in katalog) {
      final kode = b.kode.trim();
      if (kode.isEmpty) continue;
      buf
        ..write(_csvSel(kode))
        ..write(';')
        ..write(_csvSel(b.nama.trim()))
        ..write(';;\r\n');
    }
    return Uint8List.fromList(utf8.encode(buf.toString()));
  }

  static const namaBerkasSku = 'sku_baru.csv';

  static const templateSku =
      'nama;satuan;rincian;kategori;qty;harga_beli\r\n';

  static Uint8List bytesTemplateSkuBaru(BarisMasukCsv contoh) {
    final buf = StringBuffer()
      ..write('\uFEFF')
      ..write(templateSku)
      ..write(_csvSel(contoh.nama))
      ..write(';')
      ..write(_csvSel(contoh.satuan))
      ..write(';')
      ..write(_csvSel(contoh.rincian))
      ..write(';')
      ..write(_csvSel(contoh.kategori))
      ..write(';')
      ..write(contoh.qty)
      ..write(';')
      ..write(contoh.harga)
      ..write('\r\n');
    return Uint8List.fromList(utf8.encode(buf.toString()));
  }

  static BarisMasukCsv contohSkuBaru(
    List<({String kode, String nama, int harga})> katalog,
  ) {
    var harga = 10000;
    for (final b in katalog) {
      if (b.harga > 0) {
        harga = b.harga;
        break;
      }
    }
    return BarisMasukCsv(
      kode: '',
      nama: 'Contoh nama barang',
      satuan: 'pcs',
      rincian: '',
      kategori: '',
      qty: 1,
      harga: harga,
      baru: true,
    );
  }

  static String _namaRapi(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String? cekCocokKatalog(
    List<BarisMasukCsv> baris,
    Map<String, String> namaByKode,
  ) {
    final namaLower = {
      for (final e in namaByKode.entries) e.key.trim().toLowerCase(): e.value,
    };
    for (final b in baris) {
      final namaDb = namaLower[b.kode.trim().toLowerCase()];
      if (namaDb == null) {
        return 'Kode ${b.kode} tidak ada di katalog. SKU baru isi di form SKU baru.';
      }
      if (_namaRapi(namaDb) != _namaRapi(b.nama)) {
        return 'Nama ${b.kode} tidak cocok. Database: $namaDb. Berkas: ${b.nama}.';
      }
    }
    return null;
  }

  static String? cekSkuBaru(List<BarisMasukCsv> baris) {
    for (final b in baris) {
      if (b.nama.trim().isEmpty) {
        return 'SKU baru: nama wajib.';
      }
      if (b.satuan.trim().isEmpty) {
        return 'SKU baru ${b.nama}: satuan wajib.';
      }
    }
    return null;
  }

  static const _kode = {
    'kode',
    'kodebarang',
    'sku',
    'kodebrg',
  };

  static const _nama = {
    'nama',
    'namabarang',
    'namabrg',
    'barang',
  };

  static const _qty = {
    'qty',
    'jumlah',
    'qtymasuk',
    'qyt',
  };

  static const _satuan = {
    'satuan',
    'unit',
  };

  static const _rincian = {
    'rincian',
    'ket',
    'keterangan',
  };

  static const _kategori = {
    'kategori',
    'kat',
  };

  static const _harga = {
    'harga',
    'hargabeli',
    'beli',
    'hargabeliunit',
  };

  static HasilMasukCsv parseBerkas(Uint8List bytes, String namaBerkas) {
    final nama = namaBerkas.trim().toLowerCase();
    if (nama.endsWith('.xls') && !nama.endsWith('.xlsx')) {
      return const HasilMasukCsv(
        [],
        'File .xls lama tidak dibaca. Simpan sebagai .xlsx atau CSV.',
      );
    }
    if (nama.endsWith('.xlsx') || nama.endsWith('.xls')) {
      return const HasilMasukCsv(
        [],
        'Simpan sebagai CSV, lalu unggah lagi.',
      );
    }
    return parse(utf8.decode(bytes, allowMalformed: true));
  }

  static HasilMasukCsv parse(String teks) {
    final raw = teks.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    if (raw.isEmpty) {
      return const HasilMasukCsv([], 'Berkas kosong.');
    }
    final daftar = raw
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (daftar.isEmpty) {
      return const HasilMasukCsv([], 'Berkas kosong.');
    }
    final sep = _pemisah(daftar.first);
    final grid = [for (final l in daftar) _pecah(l, sep)];
    return _dariGrid(grid);
  }

  static HasilMasukCsv parseSku(String teks) {
    final raw = teks.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
    if (raw.isEmpty) {
      return const HasilMasukCsv([], 'Berkas kosong.');
    }
    final daftar = raw
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (daftar.isEmpty) {
      return const HasilMasukCsv([], 'Berkas kosong.');
    }
    final sep = _pemisah(daftar.first);
    final grid = [for (final l in daftar) _pecah(l, sep)];
    return _dariGridSku(grid);
  }

  static HasilMasukCsv _dariGridSku(List<List<String>> grid) {
    if (grid.isEmpty) {
      return const HasilMasukCsv([], 'Berkas kosong.');
    }
    final header = grid.first.map(_kunci).toList();
    final iNama = _cari(header, _nama);
    final iSatuan = _cari(header, _satuan);
    final iRincian = _cari(header, _rincian);
    final iKategori = _cari(header, _kategori);
    final iQty = _cari(header, _qty);
    final iHarga = _cari(header, _harga);
    if (iNama == null || iSatuan == null || iQty == null || iHarga == null) {
      return const HasilMasukCsv(
        [],
        'Header wajib: nama, satuan, qty, harga_beli.',
      );
    }
    final gabung = <String, BarisMasukCsv>{};
    for (var i = 1; i < grid.length; i++) {
      final kol = grid[i];
      final nama = _isi(kol, iNama);
      final satuan = _isi(kol, iSatuan);
      if (nama.isEmpty || satuan.isEmpty) continue;
      final qty = _uang(kol, iQty);
      final harga = _uang(kol, iHarga);
      if (qty <= 0 || harga <= 0) continue;
      final kunci = '${nama.toLowerCase()}|${satuan.toLowerCase()}';
      final lama = gabung[kunci];
      final rincian = iRincian == null ? '' : _isi(kol, iRincian);
      final kategori = iKategori == null ? '' : _isi(kol, iKategori);
      if (lama == null) {
        gabung[kunci] = BarisMasukCsv(
          kode: '',
          nama: nama,
          qty: qty,
          harga: harga,
          baru: true,
          satuan: satuan,
          rincian: rincian,
          kategori: kategori,
        );
      } else {
        gabung[kunci] = BarisMasukCsv(
          kode: '',
          nama: lama.nama,
          qty: lama.qty + qty,
          harga: harga,
          baru: true,
          satuan: lama.satuan,
          rincian: lama.rincian.isEmpty ? rincian : lama.rincian,
          kategori: lama.kategori.isEmpty ? kategori : lama.kategori,
        );
      }
    }
    if (gabung.isEmpty) {
      return const HasilMasukCsv(
        [],
        'Tidak ada baris dengan nama, satuan, qty, dan harga beli.',
      );
    }
    return HasilMasukCsv(gabung.values.toList());
  }

  static HasilMasukCsv _dariGrid(List<List<String>> grid) {
    if (grid.isEmpty) {
      return const HasilMasukCsv([], 'Berkas kosong.');
    }
    final header = grid.first.map(_kunci).toList();
    final iKode = _cari(header, _kode);
    final iNama = _cari(header, _nama);
    final iQty = _cari(header, _qty);
    final iHarga = _cari(header, _harga);
    if (iKode == null || iNama == null || iQty == null || iHarga == null) {
      return const HasilMasukCsv(
        [],
        'Header wajib: kode_barang, nama_barang, qty, harga_beli.',
      );
    }
    final gabung = <String, BarisMasukCsv>{};
    for (var i = 1; i < grid.length; i++) {
      final kol = grid[i];
      final kode = _kodeBarang(_isi(kol, iKode));
      if (kode.isEmpty) continue;
      final qty = _uang(kol, iQty);
      final harga = _uang(kol, iHarga);
      if (qty <= 0 || harga <= 0) continue;
      final nama = _isi(kol, iNama);
      final lama = gabung[kode];
      if (lama == null) {
        gabung[kode] = BarisMasukCsv(
          kode: kode,
          nama: nama,
          qty: qty,
          harga: harga,
        );
      } else {
        gabung[kode] = BarisMasukCsv(
          kode: kode,
          nama: lama.nama.isEmpty ? nama : lama.nama,
          qty: lama.qty + qty,
          harga: harga,
        );
      }
    }
    if (gabung.isEmpty) {
      return const HasilMasukCsv(
        [],
        'Tidak ada baris dengan kode, qty, dan harga beli.',
      );
    }
    return HasilMasukCsv(gabung.values.toList());
  }

  static String _pemisah(String header) {
    final titik = ';'.allMatches(header).length;
    final koma = ','.allMatches(header).length;
    final tab = '\t'.allMatches(header).length;
    if (tab > 0 && tab >= titik && tab >= koma) return '\t';
    if (titik > koma) return ';';
    return ',';
  }

  static List<String> _pecah(String line, String sep) {
    final out = <String>[];
    final buf = StringBuffer();
    var kutip = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        if (kutip && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          kutip = !kutip;
        }
      } else if (c == sep && !kutip) {
        out.add(buf.toString().trim());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    out.add(buf.toString().trim());
    return out;
  }

  static String _csvSel(String s) {
    if (s.contains(';') ||
        s.contains('"') ||
        s.contains(',') ||
        s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _kunci(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static int? _cari(List<String> header, Set<String> nama) {
    for (var i = 0; i < header.length; i++) {
      if (nama.contains(header[i])) return i;
    }
    return null;
  }

  static String _isi(List<String> kol, int i) =>
      i >= 0 && i < kol.length ? kol[i].trim() : '';

  static String _kodeBarang(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    final m = RegExp(r'^(\d+)\.0+$').firstMatch(t);
    if (m != null) return m.group(1)!;
    return t;
  }

  static int _uang(List<String> kol, int i) {
    final s = _isi(kol, i);
    if (s.isEmpty) return 0;
    var t = s.replaceAll(RegExp(r'\s'), '').replaceAll('Rp', '');
    if (t.contains(',') && t.contains('.')) {
      if (t.lastIndexOf(',') > t.lastIndexOf('.')) {
        t = t.replaceAll('.', '').replaceAll(',', '.');
      } else {
        t = t.replaceAll(',', '');
      }
    } else if (RegExp(r',\d{1,2}$').hasMatch(t)) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
      t = t.replaceAll('.', '');
    }
    final n = num.tryParse(t);
    if (n != null) return n.round().abs();
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }
}
