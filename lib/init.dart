import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:project_gen/project_gen.dart';

class InitCommand extends Command {
  @override
  final String name = 'init', description = 'Generates a new Polymer project.';

  @override
  run() async {
    var dir = argResults.rest.isNotEmpty
        ? new Directory(argResults.rest.first)
        : Directory.current;
    var project = new Project(p.basenameWithoutExtension(dir.path), dir);

    var dependencies = {}
      ..['polymer'] = new HostedReference.fromJson('1.0.0-rc.19')
      ..['polymer_elements'] = new HostedReference.fromJson('1.0.0-rc.9')
      ..['web_components'] = new HostedReference.fromJson('^0.12.5');

    var devDependencies = {}
      ..['browser'] = new HostedReference.fromJson('^0.10.0')
      ..['dart_to_js_script_rewriter'] = new HostedReference.fromJson('^1.0.0');

    project.root.directory('web', (web) async {
      await web
          .file('index.html')
          .copyResource('package:polygen/res/index.html');

      await web
          .file('.gitignore')
          .copyResource('package:polygen/res/.gitignore');

      await web
          .file('main.dart')
          .io
          .writeAsString("import 'components/my_app/my_app.dart';\nexport 'package:polymer/init.dart';");
    });

    project.root.file('analysis_options.yaml', (analysisOptions) {
      return analysisOptions
          .copyResource('package:polygen/res/analysis_options.yaml');
    });

    // Overwrite pubspec.yaml
    var pubspec = new PubSpec(
        name: project.name,
        version: new Version(1, 0, 0),
        publishTo: Uri.parse('none'),
        dependencies: dependencies,
        devDependencies: devDependencies);

    project.actions.add((project) async {
      project.notify.task('Modifying pubspec.yaml...');
      await pubspec.save(project.root.io);
    });

    await project.generate();

    runner.run(['element', '--class=MyApp', 'my-app']);
  }
}
