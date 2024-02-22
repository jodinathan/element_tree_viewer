import 'dart:async';
import 'dart:convert' as conv;
import 'dart:js_util';

import 'package:typings/d/vscode.dart' as vsc;
import 'package:typings/d/core.dart' as js;
import 'package:typings/d/child_process.dart' as cp;
import 'package:path/path.dart' as p;
import 'package:typings/d/ws.dart' as ws;
import 'package:ackable/ackable.dart' as ack;

class AckableWebview extends ack.Ackable with ack.OutgoingDictionary {
  AckableWebview(this.webview) {
    webview.onDidReceiveMessage((ev) {
      final dart = dartify(ev);

      print('WebViewReceive ${dart}\n${ev.runtimeType}');
      final map = dart as Map;

      _ctrl
          .add(map is Map<String, dynamic> ? map : map.cast<String, dynamic>());
    });
  }

  final vsc.Webview webview;
  late final StreamController<Map<String, dynamic>> _ctrl = controller();

  @override
  Stream<Map<String, Object?>> get onRawMessage => _ctrl.stream;

  @override
  void shoutDictionary(Map<String, dynamic> msg) {
    webview.postMessage(jsify(msg));
  }
}

ack.Ackable? _ackSocket;

Future<void> fnCmd(String dirPath) async {
  vsc.cp.exec('dart pub global run element_syntax_tree $dirPath',
      (err, stdout, stderr) {
    print('PWD');
    js.console.log([err, stdout, stderr]);
  });
}

Future<ack.Ackable> makeConnection() async {
  final current = _ackSocket;

  if (current != null) {
    return current;
  }

  final cmp = Completer<ack.Ackable>();
  final socket = ws.WebSocket('ws://localhost:4040');

  socket.on('open', ([p0, p1]) {
    final ackable = _ackSocket = ack.from(socket);

    cmp.complete(ackable);
  });

  return cmp.future;
}

Future<void> activate(vsc.ExtensionContext context,
    [bool isRestart = false]) async {
  print('Activating');
  var lastCursorPos = 0;
  void updateCursorPos() {
    final editor = vsc.vscode.window.activeTextEditor!;

    lastCursorPos = editor.document.offsetAt(editor.selection.active).toInt();
    js.console.log(['curesor2', lastCursorPos]);
  }

  final disposable =
      vsc.vscode.commands.registerCommand('dart.tree.view', ([a]) async {
    js.console.log(['make socket', a]);

    updateCursorPos();

    await vsc.vscode.commands
        .executeCommand("workbench.action.editorLayoutTwoColumns");
    await vsc.vscode.commands
        .executeCommand("workbench.action.focusSecondEditorGroup");

    final panel = vsc.vscode.window.createWebviewPanel(
        'dartTreeView',
        'Dart tree view',
        vsc.TerminalEditorLocationOptions(
            preserveFocus: true, viewColumn: vsc.ViewColumn.active),
        vsc.WebviewOptions(enableScripts: true));
    final onDiskPath =
        vsc.Uri.joinPath(context.extensionUri, ['plugin', 'main.dart.js']);
    js.console.log(['Command active!', onDiskPath]);

    try {
      js.console.log([panel.webview.asWebviewUri(onDiskPath)]);
    } catch (e) {
      print('GEE FUCK! $e');
      js.console.log(['seeeeerrrrrr', e]);
    }

    final dartJsSrc = panel.webview.asWebviewUri(onDiskPath);

    js.console.log(['dartJsSrc', dartJsSrc]);

    panel.webview.html = getWebviewContent(dartJsSrc: dartJsSrc);

    final ackable = await makeConnection();
    final result = await ackable.once('location', lastCursorPos);

    final webviewAck = AckableWebview(panel.webview)
      ..forwardOnce('sub', ackable);

    webviewAck.once('view', result);

    print('DONE! $lastCursorPos ${result is Map}');
  });

  context.subscriptions.add(disposable);

  context.subscriptions
      .add(vsc.vscode.window.onDidChangeTextEditorSelection((ev) {
    updateCursorPos();
  }));

  return;

  // final filePath = editor.document.uri.fsPath;

  // js.console.log(
  //     ['Congratulations, your extension "devee.get" is now active!', filePath]);
  // js.console
  //     .log(['curesor', editor.document.offsetAt(editor.selection.active)]);

  // if (filePath != null && false) {
  //   final dirPath = p.dirname(filePath);

  //   print('FOOOOO $dirPath');
  //   fnCmd(filePath);
  // }
}

String getWebviewContent({required vsc.Uri dartJsSrc}) {
  return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cat Coding</title>
</head>
<body>
    <script type="text/javascript" src="$dartJsSrc"></script>
</body>
</html>''';
}

void main() {
  vsc.module.exports = vsc.ModuleExports(activate: activate);

  js.console.log([vsc.process]);

  //ack.logger.onRecord.forEach((element) => print(element));
}
