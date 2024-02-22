import 'dart:convert';

extension MapUtils on Map {
  String pretty() {
    JsonEncoder encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(this);
  }
}
