import 'dart:js_interop';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:web/web.dart' as web;

QueryExecutor openConnection() => DatabaseConnection.delayed(
  Future(() async {
    try {
      await web.window.navigator.storage.persist().toDart;
    } catch (_) {
      /* Not supported by every browser. */
    }
    final result = await WasmDatabase.open(
      databaseName: 'simple_pools',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    if (result.chosenImplementation == WasmStorageImplementation.inMemory) {
      await result.resolvedExecutor.close();
      throw StateError(
        'Persistent browser storage is unavailable. Enable site storage and try again.',
      );
    }
    if (result.chosenImplementation ==
        WasmStorageImplementation.unsafeIndexedDb) {
      await result.resolvedExecutor.close();
      throw StateError(
        'Safe browser storage is unavailable. Use an up-to-date browser or the native app.',
      );
    }
    return result.resolvedExecutor;
  }),
);
