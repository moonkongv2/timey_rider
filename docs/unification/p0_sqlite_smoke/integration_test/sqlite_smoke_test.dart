// P0 experiment only. This is not the unified production schema.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native initialization, commit, rollback and reopen', (
    tester,
  ) async {
    final path =
        '${await getDatabasesPath()}/p0_probe_${DateTime.now().microsecondsSinceEpoch}.db';
    var creates = 0;
    Future<Database> open() => openDatabase(
      path,
      version: 1,
      singleInstance: false,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA journal_mode=DELETE');
        await db.execute('PRAGMA synchronous=FULL');
      },
      onCreate: (db, version) async {
        creates++;
        await db.execute(
          'CREATE TABLE probe (id INTEGER PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.insert('probe', {'id': 1, 'value': 'seed'});
      },
    );
    Database? db;
    try {
      db = await open();
      expect(creates, 1);
      expect(await db.getVersion(), 1);
      expect(
        (await db.rawQuery('PRAGMA journal_mode')).single.values.single,
        'delete',
      );
      expect((await db.rawQuery('PRAGMA synchronous')).single.values.single, 2);
      await db.transaction((txn) async {
        await txn.update(
          'probe',
          {'value': 'committed'},
          where: 'id = ?',
          whereArgs: [1],
        );
        await txn.insert('probe', {'id': 2, 'value': 'committed'});
      });
      var rolledBack = false;
      try {
        await db.transaction((txn) async {
          await txn.update(
            'probe',
            {'value': 'uncommitted'},
            where: 'id = ?',
            whereArgs: [1],
          );
          await txn.insert('probe', {'id': 3, 'value': 'uncommitted'});
          throw StateError('P0 deliberate rollback');
        });
      } on StateError catch (error) {
        expect(error.message, 'P0 deliberate rollback');
        rolledBack = true;
      }
      expect(rolledBack, isTrue);
      final expected = [
        {'id': 1, 'value': 'committed'},
        {'id': 2, 'value': 'committed'},
      ];
      expect(await db.query('probe', orderBy: 'id'), expected);
      await db.close();
      db = await open();
      expect(creates, 1, reason: 'reopen must not seed again');
      expect(await db.query('probe', orderBy: 'id'), expected);
      expect(
        (await db.rawQuery('PRAGMA integrity_check')).single.values.single,
        'ok',
      );
      // ignore: avoid_print
      print(
        'P0 VERIFIED: SQLite ${await db.rawQuery('SELECT sqlite_version()')}; '
        'create=1, commit=2 rows, rollback=0 partial rows, reopen=preserved, '
        'journal=DELETE, synchronous=FULL, integrity=ok',
      );
    } finally {
      await db?.close();
      await deleteDatabase(
        path,
      ); // Only this run's uniquely named experimental DB.
    }
  });
}
