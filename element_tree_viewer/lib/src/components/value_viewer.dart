import 'package:dart_element_tree_viewer/src/components/app.dart';
import 'package:ngdart/angular.dart';

import '../value.dart';

typedef PropertyValue = Map<String, dynamic>;

@Component(
    selector: 'value-viewer',
    styleUrls: ['value_viewer.scss.css'],
    templateUrl: 'value_viewer.html',
    directives: [coreDirectives],
    changeDetection: ChangeDetectionStrategy.onPush)
class ValueViewerComponent {
  ValueViewerComponent(this._app);

  final AppComponent _app;

  Value? _value;

  @Input('value')
  set rawValue(Map? value) {
    _value = value == null ? null : Value(value.cast<String, dynamic>());
  }

  Value get value => _value!;

  bool get hasValue => _value != null;

  bool get hasContents => value.isConstant || value.isList;

  @Input()
  bool sub = false;

  @Input()
  String key = '';

  @HostBinding('class.isViewable')
  bool get isViewable => hasValue && value.isViewable;

  @HostBinding('class.isViewing')
  bool get isViewing => hasValue && _app.isViewing && value == _app.viewing;

  String get tooltip {
    return 'Expected type ${value.isList ? 'list of' : ''} ${value.type}';
  }

  String contents() {
    if (value.isConstant) {
      final constant = value.value;

      if (constant == null) {
        return 'null';
      }

      final text = constant.toString();

      return "(${text.length > 50 ? '${text.substring(0, 50)}...' : text})";
    } else if (value.isList) {
      return '(${value.length})';
    }

    return '';
  }

  @HostListener('click')
  void view() {
    if (value.isViewable) {
      _app.view(key, value, sub: sub);
    }
  }
}
