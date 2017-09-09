import 'dart:io';
import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:barback/barback.dart';
import 'package:path/path.dart' as path;


class ModelLoader extends Transformer {
  ModelLoader.asPlugin();

  Future<bool> isPrimary(AssetId id) async => id.extension == '.dart';

  Future apply(Transform transform) async {

    final Asset asset = transform.primaryInput;

    var content = await asset.readAsString();

    CompilationUnit c = parseCompilationUnit(content);

    c.accept(new MyAstVisitor());

    var id = transform.primaryInput.id;

    transform.addOutput(new Asset.fromString(id, c.toSource()));
  }
}

class MyAstVisitor extends RecursiveAstVisitor {
  @override
  void visitMethodInvocation(node) {
    switch (node.methodName.token.lexeme) {
      case 'myLoadModel':
        var args = new List.from(node.childEntities);

        var arguments = args[1].arguments;

        String fileName = arguments.first.stringValue;

        const String shadersDir = 'models';

        String filePath = path.join(shadersDir, fileName);

        final File file = new File(filePath);

        String contents = file.readAsStringSync();

        final String replacement = '"""${contents}"""';

        SimpleStringLiteral ssl = createSimpleStringLiteral(node,
            replacement);

        node.parent.accept(new NodeReplacer(node, ssl));
        break;
    }
  }
}

SimpleStringLiteral createSimpleStringLiteral(AstNode node, String contents) {
  final StringToken st = new StringToken(
      TokenType.STRING, contents, node.offset);

  return new SimpleStringLiteral(st, contents);
}
