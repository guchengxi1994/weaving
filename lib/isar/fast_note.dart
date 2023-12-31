import 'package:date_format/date_format.dart';
import 'package:isar/isar.dart';

part 'fast_note.g.dart';

@collection
class FastNote {
  Id? id;
  String? key;
  int createAt = DateTime.now().millisecondsSinceEpoch;
  bool isFav = false;
  late String group = formatDate(DateTime.now(), [yyyy, "-", mm, "-", dd]);

  final values = IsarLinks<FastNoteValue>();

  // FastNote copyWith(
  //     {Id? id, String? key, int? createAt, bool? isFav, String? group}) {
  //   return FastNote()
  //     ..id = id ?? this.id
  //     ..key = key ?? this.key
  //     ..createAt = createAt ?? this.createAt
  //     ..isFav = isFav ?? this.isFav
  //     ..group = group ?? this.group;
  // }
}

@collection
class FastNoteValue {
  Id? id;
  late String value = "";
  bool locked = false;
}

// @collection
// class FastNoteChangelog {
//   Id? id;

//   String? key;
//   List<String> values = [];
//   int createAt = DateTime.now().millisecondsSinceEpoch;
// }

extension GroupBy on List<FastNote> {
  Map<String, List<FastNote>> groupBy() {
    final Map<String, List<FastNote>> result = {};
    for (final i in this) {
      if (result[i.group] != null) {
        result[i.group]!.add(i);
      } else {
        result[i.group] = [i];
      }
    }

    return result;
  }
}
