import 'package:collection/collection.dart';

class ReflectorInfo {
  const ReflectorInfo(this.types);

  final Iterable<Type> types;
}

sealed class ReflectProperty<P, T> {
  ReflectProperty(
      {required this.name, required this.isCore, required this.isViewable,
      required this.isMethod});

  Object? getter(Object parent);
  final String name;

  Type get type => T;
  final bool isCore;
  final bool isViewable;
  final bool isMethod;
}

final class ReflectSingleProperty<P, T> extends ReflectProperty<P, T> {
  ReflectSingleProperty(
      {required super.name,
      required final T Function(P parent) getter,
      required super.isCore,
      required super.isViewable,
      required super.isMethod})
      : _getter = getter;

  final T Function(P parent) _getter;

  @override
  T getter(Object parent) {
    assert(parent is P);
    return _getter(parent as P);
  }
}

final class ReflectIterableProperty<P extends Object, T>
    extends ReflectProperty<P, T> {
  ReflectIterableProperty(
      {required super.name,
      required Iterable<T> Function(P parent) getter,
      required super.isCore,
      required super.isViewable,
      required super.isMethod})
      : _getter = getter;

  final Iterable<T> Function(P parent) _getter;

  @override
  Iterable<T> getter(Object parent) {
    assert(parent is P);
    return _getter(parent as P);
  }
}

final class NullableReflectIterableProperty<P extends Object, T>
    extends ReflectProperty<P, T> {
  NullableReflectIterableProperty(
      {required super.name,
      required Iterable<T>? Function(P parent) getter,
      required super.isCore,
      required super.isViewable,
      required super.isMethod})
      : _getter = getter;

  final Iterable<T>? Function(P parent) _getter;

  @override
  Iterable<T>? getter(Object parent) {
    assert(parent is P);
    return _getter(parent as P);
  }
}

class ReflectItem<T> {
  ReflectItem({required Iterable<ReflectProperty<T, dynamic>> properties})
      : properties = properties.sorted((a, b) {
          if ((a.isCore || a.isViewable) && !b.isCore && !b.isViewable) {
            return -1;
          } else if ((b.isCore || b.isViewable) && !a.isCore && !a.isViewable) {
            return 1;
          }

          return a.name.compareTo(b.name);
        });

  final Iterable<ReflectProperty<T, dynamic>> properties;

  Type get type => T;

  bool checker(dynamic element) => element is T;
}
