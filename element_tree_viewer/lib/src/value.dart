import 'dart:convert';

final encoder = JsonEncoder.withIndent('  ');

extension type Value(Map<String, dynamic> _map) {
  String get kind => _map['kind'];
  String get type => _map['type'];
  String? get valueType => _map['valueType'];

  Object? get value => _map['value'];

  bool get isConstant => kind == 'constant';
  bool get isList => kind == 'list';
  bool get isKnown => _map['kind'] == 'known';
  bool get isComplex => ['known', 'unknown'].contains(_map['kind']);

  int get length => _map['length'];

  bool get isViewable => isKnown || (isList && _map['viewable'] == true);

  Iterable<String> get keys => _map.keys;

  dynamic operator [](String key) => _map[key];

  String asString() => encoder.convert(_map);
}
