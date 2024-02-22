//import 'merge.dart';
import 'run.dart';

const mainCodeFile = "web/main.dart";
const outputFinal = "plugin/extension.js";

Future build(String? params) async {
  if (await run(
          "compile js $mainCodeFile -o $outputFinal --enable-diagnostic-colors $params") ==
      0) {
    //mergeFlutterWrapper();
  }
}
