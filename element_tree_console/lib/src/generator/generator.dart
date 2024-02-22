import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

final anel = refer('ReflectItem',
    'package:element_tree_console/src/generator/reflector.dart');
final anpropList = refer('ReflectIterableProperty',
    'package:element_tree_console/src/generator/reflector.dart');
final anpropNullableList = refer('NullableReflectIterableProperty',
    'package:element_tree_console/src/generator/reflector.dart');
final anproperty = refer('ReflectSingleProperty',
    'package:element_tree_console/src/generator/reflector.dart');

class MetadataLibraryGenerator extends Generator {
  bool canUseExecutableElement(ExecutableElement prop) =>
      !prop.isSynthetic && prop.isPublic && !prop.isOperator && !prop.isStatic;

  bool canUseProp(PropertyAccessorElement prop) =>
      canUseExecutableElement(prop) && prop.isGetter;

  bool canUseMethod(MethodElement prop) =>
      canUseExecutableElement(prop) && prop.parameters.isEmpty;

  final List<ClassElement> classes = [];
  late final Resolver resolver;

  bool canUseClass(ClassElement classElement) => classElement.isPublic;

  Future<Iterable<ClassElement>> classesFromUri(String uri) async {
    final coreView = await resolver.libraryFor(AssetId.resolve(Uri.parse(uri)));

    return coreView.topLevelElements
        .whereType<ClassElement>()
        .where(canUseClass);
  }

  Future<Iterable<ClassElement>> classesFromUris(Iterable<String> uris) async {
    final ret = <ClassElement>[];

    for (final uri in uris) {
      ret.addAll(await classesFromUri(uri));
    }

    return ret;
  }

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
     resolver = buildStep.resolver;

    try {
      classes.addAll(await classesFromUris([
        'package:analyzer/dart/element/element.dart',
        'package:analyzer/dart/constant/value.dart'
      ]));

      final elements = await execute(classes);

      final libraryBuilder = Library((b) => b.body.addAll([
            declareFinal('\$reflectedElement')
                .assign(literalList(elements))
                .statement
          ]));
      final emitter = DartEmitter.scoped(useNullSafetySyntax: true);
      final buf = libraryBuilder.accept(emitter).toString();

      try {
        return DartFormatter().format(buf);
      } catch (e) {
        log.severe('Format error $e');
        return buf;
      }
    } catch (e, st) {
      print('ERROR :$e\n$st');
      rethrow;
    }
  }

  Expression? processItem(Element element) {
    final name = element.name;

    if (name == null) {
      return null;
    }

    final elementRef = refer(name, element.librarySource!.uri.toString());
    final getters = <PropertyAccessorElement>[];
    final methods = <MethodElement>[];

    if (element is InterfaceElement) {
      getters.addAll(element.accessors.where(canUseProp));
      methods.addAll(element.methods.where(canUseMethod));

      for (final sup in element.allSupertypes) {
        for (final accessor in sup.accessors.where(canUseProp)) {
          if (!getters.any((g) => g.name == accessor.name)) {
            getters.add(accessor);
          }
        }

        for (final method in sup.methods.where(canUseMethod)) {
          if (!methods.any((g) => g.name == method.name)) {
            methods.add(method);
          }
        }
      }
    }

    return anel.call([], {
      'properties': literalList([
        ...getters.map((g) => _makeProp(g, elementRef)),
        ...methods.map((g) => _makeProp(g, elementRef, isMethod: true))
      ])
    }, [
      refer(name, element.library?.source.uri.toString())
    ]);
  }

  Expression _makeProp(ExecutableElement g, Reference elementRef,
      {bool isMethod = false}) {
    final returns = g.returnType;
    Reference ref;
    Reference refTypeParam;
    DartType type;

    if (g.returnType.isDartCoreIterable || g.returnType.isDartCoreList) {
      type = (returns as InterfaceType).typeArguments.first;

      ref = g.returnType.nullabilitySuffix == NullabilitySuffix.question
          ? anpropNullableList
          : anpropList;
    } else {
      type = returns;
      ref = anproperty;
    }

    var originalType = type;

    if (type case TypeParameterType alias) {
      type = alias.bound;
    }

    Reference buildType(DartType type, {bool? isNullable}) {
      return TypeReference((b) {
        b
          ..symbol = type.element!.displayName
          ..url = type.element!.librarySource!.uri.toString()
          ..isNullable = 
              isNullable ?? type.nullabilitySuffix == NullabilitySuffix.question
          ..types.addAll([
            if (type is InterfaceType)
              ...type.typeArguments.map((ta) => buildType(ta))
          ]);
      });
    }

    refTypeParam = buildType(type,
        isNullable:
            originalType.nullabilitySuffix == NullabilitySuffix.question);

    final isCore = type.isDartCoreBool ||
        type.isDartCoreDouble ||
        type.isDartCoreEnum ||
        type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreNum ||
        type.isDartCoreString ||
        type.isDartCoreNum;
    final viewable = classes.contains(type.element!);

    return ref.call([], {
      'name': literalString(g.name),
      'isCore': literalBool(isCore),
      'isViewable': literalBool(viewable),
      'isMethod': literalBool(isMethod),
      'getter': Method((b) {
        final prop = refer('object').property(g.name);

        b
          ..requiredParameters.add(Parameter((b) {
            b.name = 'object';
          }))
          ..body = isMethod ? prop.call([]).code : prop.code;
      }).closure
    }, [
      elementRef,
      refTypeParam
    ]);
  }

  Future<List<Expression>> execute(Iterable<ClassElement> classElements) async {
    final anels = <Expression>[];

    for (final element in classElements) {
      final getters = <PropertyAccessorElement>[
        ...element.accessors.where(canUseProp)
      ];

      for (final sup in element.allSupertypes) {
        for (final accessor in sup.accessors.where(canUseProp)) {
          if (!getters.any((g) => g.name == accessor.name)) {
            getters.add(accessor);
          }
        }
      }

      final exp = processItem(element);

      if (exp != null) {
        anels.add(exp);
      }
    }

    return anels;
  }
}
