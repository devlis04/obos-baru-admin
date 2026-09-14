import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');
  final url = (dotenv.env['SUPABASE_URL'] ?? '').trim();
  final kunci = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
  if (url.isEmpty || kunci.isEmpty) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Tema.terang(),
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Isi assets/.env dengan SUPABASE_URL dan SUPABASE_ANON_KEY '
                '(salin dari app gudang baru).',
                style: TextStyle(height: 1.4, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }
  await Supabase.initialize(
    url: url,
    // ignore: deprecated_member_use
    anonKey: kunci,
    postgrestOptions: const PostgrestClientOptions(schema: 'obos'),
  );
  runApp(const AppAdmin());
}
