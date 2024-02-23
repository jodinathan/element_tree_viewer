import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js_interop';
import 'dart:js_util';

import 'package:dart_element_tree_viewer/src/components/value_viewer.dart';
import 'package:dart_element_tree_viewer/src/value.dart';
import 'package:ngdart/angular.dart';
import 'package:ackable/ackable.dart' as ack;

@JS()
external VsCodeApi acquireVsCodeApi();

@JS()
@staticInterop
@anonymous
class VsCodeApi {}

extension JsVsCodeApi on VsCodeApi {
  void postMessage(Object? data) => callMethod(this, 'postMessage', [data]);
}

final encoder = JsonEncoder.withIndent('  ');

class Walk {
  Walk(this.key, this.value);

  final String key;
  final Value value;

  int index = 0;

  Iterable<String> get path => [key, if (value.isList) index.toString()];

  String get prettyPath => '$key${value.isList ? '[$index]' : ''}';
}

class AckableWindowMessage extends ack.Ackable with ack.OutgoingDictionary {
  final _vsCodeApi = acquireVsCodeApi();

  @override
  Stream<Map<String, Object?>> get onRawMessage => window.onMessage
      .where((event) => event.data is Map)
      .map((event) => event.data.cast<String, dynamic>());

  @override
  void shoutDictionary(Map<String, dynamic> msg) {
    _vsCodeApi.postMessage(jsify(msg));
  }
}

class ListItem {
  final int index;
  final String label;
  const ListItem(this.index, this.label);

  String get uiDisplayName => label;

  @override
  String toString() => '$index => $uiDisplayName';
}

@Component(
    selector: 'my-app',
    styleUrls: ['app.scss.css'],
    templateUrl: 'app.html',
    directives: [
      coreDirectives,
      ValueViewerComponent,
    ],
    changeDetection: ChangeDetectionStrategy.onPush,
    visibility: Visibility.all)
class AppComponent {
  AppComponent(this._ref) {
    _windowMsgAck.onCommand('view', (message) {
      final result = (message.data as Iterable).cast<Map>().first;

      _item = result is Map<String, dynamic>
          ? result
          : result.cast<String, dynamic>();
      _ref.markForCheck();
    });
  }

  final _windowMsgAck = AckableWindowMessage();
  final ChangeDetectorRef _ref;
  // var _cc = 0;

  bool get hasResult => _item != null;

  Map<String, dynamic>? _item;
  Map<String, dynamic> get item => _item!;

  Value? _viewing;
  Value get viewing => _viewing!;

  bool get isViewing => _viewing != null;

  List<ListItem>? _viewingOptions;
  List<ListItem> get viewingOptions => _viewingOptions!;

  ListItem? chosenViewingOption;

  String _subitemKey = '';
  String get subitemKey => _subitemKey;

  Value? _subitem;
  Value get subitem => _subitem!;

  bool get hasSubItem => _subitem != null;

  final List<Walk> walked = [];

  Walk? _currentWalk;
  Walk get currentWalk => _currentWalk!;

  bool _isFetching = true;
  bool get isFetching => _isFetching;

  @ViewChild('sel')
  SelectElement? select;

  void body(dynamic buf) {
    document.body!.children.add(PreElement()..innerText = buf.toString());
  }

  void view(String key, Value value, {bool sub = false}) {
    _isFetching = true;
    _viewing = value;
    _subitemKey = key;

    if (!sub) {
      walked.clear();
    }

    _currentWalk = Walk(key, value);
    walked.add(currentWalk);

    chosenViewingOption = _viewingOptions = null;

    if (viewing.isList) {
      _viewingOptions = [
        for (var x = 0; x < viewing.length; x++) ListItem(x, 'Item #${x + 1}'),
      ];
      chosenViewingOption = viewingOptions.firstOrNull;
    }

    fetchSubitem();

    // _cc++;
    // if (_cc == 1) {
    //   chooseSubitem(subItems1[0] as Value);
    // } else {
    //   chooseSubitem(subItems2 as Value);
    // }
  }

  void fetchSubitem() {
    final path = walked.expand((w) => w.path);

    _windowMsgAck.once('sub', path).then((ev) {
      final items = (ev as Iterable).cast<Map>();

      chooseSubitem(items.firstOrNull?.cast<String, dynamic>() as Value?);
    });
  }

  void chooseViewingOption(Event event) {
    final index = select!.selectedIndex!;
    final listItem = viewingOptions.elementAt(index);

    chosenViewingOption = listItem;
    
    if (currentWalk.index != index) {
      currentWalk.index = viewingOptions.indexOf(listItem);
      fetchSubitem();
    }
  }

  void chooseSubitem(Value? newSubItem) {
    _subitem = newSubItem;
    _isFetching = false;
    _ref.markForCheck();
  }
}

const subItems1 = [
  {
    "computeConstantValue": {
      "type": "DartObject?",
      "valueType": "DartObjectImpl",
      "value": {"type": "ElementAnnotation"},
      "kind": "known"
    },
    "element": {
      "type": "Element?",
      "valueType": "ConstructorElementImpl",
      "value": {"type": "ElementAnnotation"},
      "kind": "known"
    },
    "hashCode": {
      "type": "int",
      "valueType": "int",
      "value": 374259371,
      "kind": "constant"
    },
    "isAlwaysThrows": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isConstantEvaluated": {
      "type": "bool",
      "valueType": "bool",
      "value": true,
      "kind": "constant"
    },
    "isDeprecated": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isDoNotStore": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isFactory": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isImmutable": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isInternal": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isIsTest": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isIsTestGroup": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isJS": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isLiteral": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isMustBeOverridden": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isMustCallSuper": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isNonVirtual": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isOptionalTypeArgs": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isOverride": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isProtected": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isProxy": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isRedeclare": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isReopen": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isRequired": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isSealed": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isTarget": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isUseResult": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isVisibleForOverriding": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isVisibleForTemplate": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isVisibleForTesting": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isVisibleOutsideTemplate": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "library": {
      "type": "LibraryElement?",
      "valueType": "LibraryElementImpl",
      "value": {"type": "ElementAnnotation"},
      "kind": "known"
    },
    "toSource": {
      "type": "String",
      "valueType": "String",
      "value": "@Ann('bufFFF', foo: 123, ann: ann2)",
      "kind": "constant"
    },
    "toString": {
      "type": "String",
      "valueType": "String",
      "value": "@Ann Ann(String buf, {required double foo, int? nn, Ann? ann})",
      "kind": "constant"
    },
    "constantEvaluationErrors": {
      "type": "AnalysisError",
      "valueType": "List<AnalysisError>",
      "value": "List<AnalysisError>",
      "kind": "unknown"
    },
    "context": {
      "type": "AnalysisContext",
      "valueType": "AnalysisContextImpl",
      "value": "AnalysisContext",
      "kind": "unknown"
    },
    "librarySource": {
      "type": "Source?",
      "valueType": "FileSource",
      "value": "FileSource",
      "kind": "unknown"
    },
    "runtimeType": {
      "type": "Type",
      "valueType": "Type",
      "value": "Type",
      "kind": "unknown"
    },
    "source": {
      "type": "Source?",
      "valueType": "FileSource",
      "value": "FileSource",
      "kind": "unknown"
    }
  }
];

const subItems2 = {
  "accessors": {
    "type": "PropertyAccessorElement",
    "valueType": "List<PropertyAccessorElementImpl>",
    "length": 1,
    "viewable": true,
    "kind": "list"
  },
  "children": {
    "type": "Element",
    "valueType": "List<Element>",
    "length": 13,
    "viewable": true,
    "kind": "list"
  },
  "classes": {
    "type": "ClassElement",
    "valueType": "List<ClassElementImpl>",
    "length": 6,
    "viewable": true,
    "kind": "list"
  },
  "declaration": {
    "type": "Element",
    "valueType": "CompilationUnitElementImpl",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "displayName": {
    "type": "String",
    "valueType": "String",
    "value": "",
    "kind": "constant"
  },
  "documentationComment": {
    "type": "String?",
    "valueType": null,
    "value": null,
    "kind": "constant"
  },
  "enclosingElement": {
    "type": "LibraryOrAugmentationElement",
    "valueType": "LibraryElementImpl",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "enums": {
    "type": "EnumElement",
    "valueType": "List<Never>",
    "length": 0,
    "viewable": true,
    "kind": "list"
  },
  "extensionTypes": {
    "type": "ExtensionTypeElement",
    "valueType": "List<Never>",
    "length": 0,
    "viewable": true,
    "kind": "list"
  },
  "extensions": {
    "type": "ExtensionElement",
    "valueType": "List<Never>",
    "length": 0,
    "viewable": true,
    "kind": "list"
  },
  "functions": {
    "type": "FunctionElement",
    "valueType": "List<FunctionElementImpl>",
    "length": 1,
    "viewable": true,
    "kind": "list"
  },
  "hasAlwaysThrows": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasDeprecated": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasDoNotStore": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasFactory": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasInternal": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasIsTest": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasIsTestGroup": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasJS": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasLiteral": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasMustBeOverridden": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasMustCallSuper": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasNonVirtual": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasOptionalTypeArgs": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasOverride": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasProtected": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasRedeclare": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasReopen": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasRequired": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasSealed": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasUseResult": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasVisibleForOverriding": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasVisibleForTemplate": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasVisibleForTesting": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hasVisibleOutsideTemplate": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "hashCode": {
    "type": "int",
    "valueType": "int",
    "value": 165922450,
    "kind": "constant"
  },
  "id": {"type": "int", "valueType": "int", "value": 18655, "kind": "constant"},
  "isPrivate": {
    "type": "bool",
    "valueType": "bool",
    "value": true,
    "kind": "constant"
  },
  "isPublic": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "isSynthetic": {
    "type": "bool",
    "valueType": "bool",
    "value": false,
    "kind": "constant"
  },
  "kind": {
    "type": "ElementKind",
    "valueType": "ElementKind",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "library": {
    "type": "LibraryElement",
    "valueType": "LibraryElementImpl",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "location": {
    "type": "ElementLocation?",
    "valueType": "ElementLocationImpl",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "metadata": {
    "type": "ElementAnnotation",
    "valueType": "List<ElementAnnotation>",
    "length": 0,
    "viewable": true,
    "kind": "list"
  },
  "mixins": {
    "type": "MixinElement",
    "valueType": "List<MixinElementImpl>",
    "length": 3,
    "viewable": true,
    "kind": "list"
  },
  "name": {
    "type": "String?",
    "valueType": null,
    "value": null,
    "kind": "constant"
  },
  "nameLength": {
    "type": "int",
    "valueType": "int",
    "value": 0,
    "kind": "constant"
  },
  "nameOffset": {
    "type": "int",
    "valueType": "int",
    "value": -1,
    "kind": "constant"
  },
  "nonSynthetic": {
    "type": "Element",
    "valueType": "CompilationUnitElementImpl",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "thisOrAncestorOfType": {
    "type": "Element?",
    "valueType": "CompilationUnitElementImpl",
    "value": {"type": "LibraryElement"},
    "kind": "known"
  },
  "toString": {
    "type": "String",
    "valueType": "String",
    "value":
        "/Users/jonathanrezende/Projects/dart/public/element_syntax_tree/lib/src/example.dart",
    "kind": "constant"
  },
  "topLevelVariables": {
    "type": "TopLevelVariableElement",
    "valueType": "List<TopLevelVariableElementImpl>",
    "length": 1,
    "viewable": true,
    "kind": "list"
  },
  "typeAliases": {
    "type": "TypeAliasElement",
    "valueType": "List<TypeAliasElementImpl>",
    "length": 1,
    "viewable": true,
    "kind": "list"
  },
  "uri": {
    "type": "String?",
    "valueType": null,
    "value": null,
    "kind": "constant"
  },
  "uriEnd": {
    "type": "int",
    "valueType": "int",
    "value": -1,
    "kind": "constant"
  },
  "uriOffset": {
    "type": "int",
    "valueType": "int",
    "value": -1,
    "kind": "constant"
  },
  "context": {
    "type": "AnalysisContext",
    "valueType": "AnalysisContextImpl",
    "value": "AnalysisContext",
    "kind": "unknown"
  },
  "librarySource": {
    "type": "Source",
    "valueType": "FileSource",
    "value": "FileSource",
    "kind": "unknown"
  },
  "lineInfo": {
    "type": "LineInfo",
    "valueType": "LineInfo",
    "value": "LineInfo",
    "kind": "unknown"
  },
  "runtimeType": {
    "type": "Type",
    "valueType": "Type",
    "value": "Type",
    "kind": "unknown"
  },
  "session": {
    "type": "AnalysisSession",
    "valueType": "AnalysisSessionImpl",
    "value": "AnalysisSession",
    "kind": "unknown"
  },
  "sinceSdkVersion": {
    "type": "Version?",
    "valueType": null,
    "value": "Null",
    "kind": "unknown"
  },
  "source": {
    "type": "Source",
    "valueType": "FileSource",
    "value": "FileSource",
    "kind": "unknown"
  }
};

const testeItems = [
  {
    "accessors": {
      "type": "PropertyAccessorElement",
      "valueType": "List<PropertyAccessorElementImpl>",
      "length": 9,
      "viewable": true,
      "kind": "list"
    },
    "augmentation": {
      "type": "ClassElement?",
      "valueType": null,
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "augmentationTarget": {
      "type": "ClassElement?",
      "valueType": null,
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "augmented": {
      "type": "AugmentedClassElement?",
      "valueType": "NotAugmentedClassElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "children": {
      "type": "Element",
      "valueType": "List<Element>",
      "length": 16,
      "viewable": true,
      "kind": "list"
    },
    "constructors": {
      "type": "ConstructorElement",
      "valueType": "List<ConstructorElementImpl>",
      "length": 1,
      "viewable": true,
      "kind": "list"
    },
    "declaration": {
      "type": "Element?",
      "valueType": "ClassElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "displayName": {
      "type": "String",
      "valueType": "String",
      "value": "FullClass",
      "kind": "constant"
    },
    "documentationComment": {
      "type": "String?",
      "valueType": "String",
      "value": "/// Oh Yeah some doc!",
      "kind": "constant"
    },
    "enclosingElement": {
      "type": "CompilationUnitElement",
      "valueType": "CompilationUnitElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "fields": {
      "type": "FieldElement",
      "valueType": "List<FieldElementImpl>",
      "length": 5,
      "viewable": true,
      "kind": "list"
    },
    "hasAlwaysThrows": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasDeprecated": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasDoNotStore": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasFactory": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasInternal": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasIsTest": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasIsTestGroup": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasJS": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasLiteral": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasMustBeOverridden": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasMustCallSuper": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasNonFinalField": {
      "type": "bool",
      "valueType": "bool",
      "value": true,
      "kind": "constant"
    },
    "hasNonVirtual": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasOptionalTypeArgs": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasOverride": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasProtected": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasRedeclare": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasReopen": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasRequired": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasSealed": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasUseResult": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasVisibleForOverriding": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasVisibleForTemplate": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasVisibleForTesting": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hasVisibleOutsideTemplate": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "hashCode": {
      "type": "int",
      "valueType": "int",
      "value": 221724925,
      "kind": "constant"
    },
    "id": {
      "type": "int",
      "valueType": "int",
      "value": 18661,
      "kind": "constant"
    },
    "isAbstract": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isAugmentation": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isBase": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isConstructable": {
      "type": "bool",
      "valueType": "bool",
      "value": true,
      "kind": "constant"
    },
    "isDartCoreEnum": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isDartCoreObject": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isExhaustive": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isFinal": {
      "type": "bool",
      "valueType": "bool",
      "value": true,
      "kind": "constant"
    },
    "isInline": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isInterface": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isMixinApplication": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isMixinClass": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isPrivate": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isPublic": {
      "type": "bool",
      "valueType": "bool",
      "value": true,
      "kind": "constant"
    },
    "isSealed": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isSimplyBounded": {
      "type": "bool",
      "valueType": "bool",
      "value": true,
      "kind": "constant"
    },
    "isSynthetic": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "isValidMixin": {
      "type": "bool",
      "valueType": "bool",
      "value": false,
      "kind": "constant"
    },
    "kind": {
      "type": "ElementKind",
      "valueType": "ElementKind",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "library": {
      "type": "LibraryElement?",
      "valueType": "LibraryElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "location": {
      "type": "ElementLocation?",
      "valueType": "ElementLocationImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "metadata": {
      "type": "ElementAnnotation",
      "valueType": "List<ElementAnnotation>",
      "length": 1,
      "viewable": true,
      "kind": "list"
    },
    "methods": {
      "type": "MethodElement",
      "valueType": "List<MethodElementImpl>",
      "length": 1,
      "viewable": true,
      "kind": "list"
    },
    "name": {
      "type": "String",
      "valueType": "String",
      "value": "FullClass",
      "kind": "constant"
    },
    "nameLength": {
      "type": "int",
      "valueType": "int",
      "value": 9,
      "kind": "constant"
    },
    "nameOffset": {
      "type": "int",
      "valueType": "int",
      "value": 176,
      "kind": "constant"
    },
    "nonSynthetic": {
      "type": "Element",
      "valueType": "ClassElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "thisOrAncestorOfType": {
      "type": "Element?",
      "valueType": "ClassElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "toString": {
      "type": "String",
      "valueType": "String",
      "value":
          "final class FullClass extends SuperClass<dynamic> with Mixer, Mixer2 implements SuperInterface<num, SuperInterface2<String>, num>, SuperInterface3<SuperInterface2<SuperInterface2<num>>>",
      "kind": "constant"
    },
    "typeParameters": {
      "type": "TypeParameterElement",
      "valueType": "List<TypeParameterElement>",
      "length": 0,
      "viewable": true,
      "kind": "list"
    },
    "unnamedConstructor": {
      "type": "ConstructorElement?",
      "valueType": "ConstructorElementImpl",
      "value": {"type": "ClassElement"},
      "kind": "known"
    },
    "allSupertypes": {
      "type": "InterfaceType",
      "valueType": "List<InterfaceType>",
      "length": 6,
      "kind": "list"
    },
    "context": {
      "type": "AnalysisContext",
      "valueType": "AnalysisContextImpl",
      "value": "AnalysisContext",
      "kind": "unknown"
    },
    "interfaces": {
      "type": "InterfaceType",
      "valueType": "List<InterfaceType>",
      "length": 2,
      "kind": "list"
    },
    "librarySource": {
      "type": "Source?",
      "valueType": "FileSource",
      "value": "FileSource",
      "kind": "unknown"
    },
    "mixins": {
      "type": "InterfaceType",
      "valueType": "List<InterfaceType>",
      "length": 2,
      "kind": "list"
    },
    "runtimeType": {
      "type": "Type",
      "valueType": "Type",
      "value": "Type",
      "kind": "unknown"
    },
    "session": {
      "type": "AnalysisSession?",
      "valueType": "AnalysisSessionImpl",
      "value": "AnalysisSession",
      "kind": "unknown"
    },
    "sinceSdkVersion": {
      "type": "Version?",
      "valueType": null,
      "value": "Null",
      "kind": "unknown"
    },
    "source": {
      "type": "Source?",
      "valueType": "FileSource",
      "value": "FileSource",
      "kind": "unknown"
    },
    "supertype": {
      "type": "InterfaceType?",
      "valueType": "InterfaceTypeImpl",
      "value": "InterfaceType",
      "kind": "unknown"
    },
    "thisType": {
      "type": "InterfaceType",
      "valueType": "InterfaceTypeImpl",
      "value": "InterfaceType",
      "kind": "unknown"
    }
  }
];
