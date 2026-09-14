import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obos_admin/tema.dart';

void main() {
  test('tema punya warna seed', () {
    expect(Tema.seed, const Color(0xFF1B75CB));
    expect(Tema.terang().colorScheme.primary, Tema.seed);
  });
}
