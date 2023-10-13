import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:interesting_things_collection/catalog/catalog_notifier.dart';
import 'package:interesting_things_collection/catalog/components/catalog_card.dart';
import 'package:reorderables/reorderables.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(catalogNotifier);

    return StreamBuilder(
        stream: notifier.streamController.stream,
        builder: (c, s) {
          if (s.hasData) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ReorderableWrap(
                spacing: 40,
                runSpacing: 40,
                onReorder: (int oldIndex, int newIndex) async {
                  if (s.data!.isEmpty || s.data!.length == 1) {
                    return;
                  }
                  ref.read(catalogNotifier).changeIndex(oldIndex, newIndex);
                },
                children: s.data!
                    .map((e) => CatalogCard(
                          catalog: e,
                        ))
                    .toList(),
              ),
            );
          }
          return Container();
        });
  }
}