import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<bool> unduhCsv(String nama, String isi) async {
  final win = web.window as JSObject;
  if (!win.has('showSaveFilePicker')) {
    throw StateError('Penyimpanan file tidak tersedia di browser ini.');
  }
  try {
    final accept = JSObject()
      ..setProperty('text/csv'.toJS, <JSString>['.csv'.toJS].toJS);
    final jenis = JSObject()
      ..setProperty('description'.toJS, 'CSV'.toJS)
      ..setProperty('accept'.toJS, accept);
    final opts = JSObject()
      ..setProperty('suggestedName'.toJS, nama.toJS)
      ..setProperty('types'.toJS, <JSObject>[jenis].toJS);

    final handle = await win
        .callMethod<JSPromise<web.FileSystemFileHandle>>(
          'showSaveFilePicker'.toJS,
          opts,
        )
        .toDart;
    final tulis = await handle.createWritable().toDart;
    final bytes = Uint8List.fromList(utf8.encode(isi));
    await tulis.write(bytes.toJS).toDart;
    await tulis.close().toDart;
    return true;
  } catch (e) {
    if (e.isA<web.DOMException>()) {
      final namaGalat = (e as JSObject)
          .getProperty<JSString?>('name'.toJS)
          ?.toDart;
      if (namaGalat == 'AbortError') return false;
    }
    final t = e.toString();
    if (t.contains('AbortError') || t.contains('abort')) return false;
    rethrow;
  }
}

Future<String?> pilihCsv() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.csv,.txt,text/csv,text/plain'
    ..style.display = 'none';
  web.document.body!.append(input);

  final selesai = Completer<String?>();

  void tutup(String? teks) {
    input.remove();
    if (!selesai.isCompleted) selesai.complete(teks);
  }

  input.addEventListener(
    'change',
    (web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        tutup(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        tutup(null);
        return;
      }
      final reader = web.FileReader();
      reader.addEventListener(
        'load',
        (web.Event _) {
          final hasil = reader.result;
          if (hasil == null) {
            tutup(null);
            return;
          }
          tutup((hasil as JSString).toDart);
        }.toJS,
      );
      reader.addEventListener(
        'error',
        ((web.Event _) => tutup(null)).toJS,
      );
      reader.readAsText(file);
    }.toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => tutup(null)).toJS);

  input.click();
  return selesai.future.timeout(
    const Duration(minutes: 2),
    onTimeout: () {
      tutup(null);
      return null;
    },
  );
}
