import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openConnection() => LazyDatabase(() async {
  final directory = await getApplicationSupportDirectory();
  await directory.create(recursive: true);
  return NativeDatabase.createInBackground(
    File(p.join(directory.path, 'simple_pools.sqlite')),
  );
});
