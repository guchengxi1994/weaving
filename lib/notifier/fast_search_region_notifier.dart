import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:weaving/isar/database.dart';
import 'package:weaving/isar/thing.dart';

class FastSearchRegionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  changeStatus(bool b) {
    if (state != b) {
      state = b;
    }
  }

  final IsarDatabase isarDatabase = IsarDatabase();

  queryAll(String text) async {
    if (text == "") {
      return;
    }

    final things = await isarDatabase.isar!.things
        .filter()
        .fullTextContains(text)
        .findAll();

    for (final i in things) {
      print(i.remark);
    }
  }
}

final fastSearchNotifier = NotifierProvider<FastSearchRegionNotifier, bool>(
    () => FastSearchRegionNotifier());