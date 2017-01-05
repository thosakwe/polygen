import 'package:args/command_runner.dart';
import 'package:polygen/polygen.dart';

main(List<String> args) {
  var runner = new CommandRunner('polygen', 'Dart Polymer CLI tool')
    ..addCommand(new InitCommand())
    ..addCommand(new ElementCommand());
  return runner.run(args);
}
