@TestOn('browser')
import 'package:ngtest/ngtest.dart';
import 'package:test/test.dart';
import 'package:dart_element_tree_viewer/src/components/app.dart';
import 'package:dart_element_tree_viewer/app_component.template.dart' as ng;

// Testing info: https://angulardart.xyz/guide/testing

void main() {
  final testBed = NgTestBed<AppComponent>(ng.AppComponentNgFactory);
  late NgTestFixture<AppComponent> fixture;

  setUp(() async {
    fixture = await testBed.create();
  });

  tearDown(disposeAnyRunningTest);

  test('heading', () {
    expect(fixture.text, contains('My First AngularDart App'));
  });
}
