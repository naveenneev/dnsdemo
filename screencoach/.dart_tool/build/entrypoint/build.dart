// Ensure that the build script itself is not opted in to null safety,
// instead of taking the language version from the current package.
//
// @dart=2.9
//
// ignore_for_file: directives_ordering

import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'dart:isolate' as _i2;
import 'package:build_runner/build_runner.dart' as _i3;
import 'dart:io' as _i4;

final _builders = <_i1.BuilderApplication>[];
void main(List<String> args, [_i2.SendPort sendPort]) async {
  var result = await _i3.run(args, _builders);
  sendPort?.send(result);
  _i4.exitCode = result;
}
