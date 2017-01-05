import 'package:analyzer/dart/ast/ast.dart';
import 'package:args/command_runner.dart';
import 'package:code_builder/code_builder.dart';
import 'package:console/console.dart';
import 'package:id/id.dart';
import 'package:project_gen/project_gen.dart';

_validStr(String str) => str?.isNotEmpty == true;

class ElementCommand extends Command {
  @override
  final String name = 'element', description = 'Generates a new element.';

  ElementCommand() : super() {
    argParser.addOption('class',
        abbr: 'c', help: 'The name of the class to generate.');
  }

  @override
  run() async {
    var project = await Project.load();

    String name;

    if (argResults.rest.isNotEmpty)
      name = argResults.rest.first;
    else {
      name =
          await new Prompter('Element tag name: ').prompt(checker: _validStr);
    }

    String componentName = argResults['class'] ??
        await new Prompter('Element class name: ').prompt(checker: _validStr);

    var snake = idFromString(name.toLowerCase().replaceAll('-', '_')).snake;
    var elementDir = project.root.directory('web/components/$snake');

    var html = elementDir.file('$snake.html');
    await html.io.writeAsString(_generateHtml(name));

    var dart = elementDir.file('$snake.dart');
    await dart.io.writeAsString(_generateDart(name, snake, componentName));

    project.notify.success('Successfully created element $name.');
  }

  String _generateHtml(String name) {
    return '''
<dom-module id="$name">
  <template>
    <h1>Hello, world!</h1>
  </template>
</dom-module>
    '''
        .trim();
  }

  String _generateDart(String name, String snake, String componentName) {
    var lib = new LibraryBuilder('components.$snake')
      ..addDirective(new ImportBuilder('package:polymer/polymer.dart'))
      ..addDirective(
          new ImportBuilder('package:web_components/web_components.dart')
            ..show('HtmlImport'));

    var clazz = new ClassBuilder(componentName,
        asExtends: new TypeBuilder('PolymerElement'))
      ..addAnnotation(
          new TypeBuilder('PolymerRegister').newInstance([literal(name)]));

    clazz.addConstructor(new ConstructorBuilder(
        name: 'created', superName: 'created', invokeSuper: []));

    lib.addMember(clazz);

    var ast = lib.buildAst();
    var astLib = ast.directives.first as LibraryDirective;
    astLib.metadata.add(new TypeBuilder('HtmlImport')
        .constInstance([literal('$snake.html')]).buildAnnotation());

    return prettyToSource(ast);
  }
}
