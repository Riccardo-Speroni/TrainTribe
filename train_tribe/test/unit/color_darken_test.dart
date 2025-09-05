import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:train_tribe/widgets/train_card.dart';

void main() {
  test('testColorDarken darkens color', () {
    final c = const Color(0xFF80C080); // mid green
    final darker = testColorDarken(c, 0.2);
    expect(darker.value, isNot(equals(c.value)));
  });
}
