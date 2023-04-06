import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:collection/collection.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:platform_ui/platform_ui.dart';
import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/shared/page_window_title_bar.dart';
import 'package:spotube/provider/blacklist_provider.dart';
import 'package:tuple/tuple.dart';

class BlackListPage extends HookConsumerWidget {
  const BlackListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final blacklist = ref.watch(BlackListNotifier.provider);
    final searchText = useState("");

    final filteredBlacklist = useMemoized(
      () {
        if (searchText.value.isEmpty) {
          return blacklist;
        }
        return blacklist
            .map((e) => Tuple2(
                  weightedRatio("${e.name} ${e.type.name}", searchText.value),
                  e,
                ))
            .sorted((a, b) => b.item1.compareTo(a.item1))
            .where((e) => e.item1 > 50)
            .map((e) => e.item2)
            .toList();
      },
      [blacklist, searchText.value],
    );

    return PlatformScaffold(
      appBar: PageWindowTitleBar(
        center: const PlatformText("Blacklist"),
        centerTitle: true,
        leading: const PlatformBackButton(),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: platform == TargetPlatform.windows
                ? const EdgeInsets.all(8.0).copyWith(left: 45)
                : const EdgeInsets.all(8.0),
            child: PlatformTextField(
              onChanged: (value) => searchText.value = value,
              placeholder: "Search",
              prefixIcon: SpotubeIcons.search,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: filteredBlacklist.length,
            itemBuilder: (context, index) {
              final item = filteredBlacklist.elementAt(index);
              return PlatformListTile(
                leading: PlatformText("${index + 1}."),
                title: PlatformText("${item.name} (${item.type.name})"),
                subtitle: PlatformText.caption(item.id),
                trailing: PlatformIconButton(
                  icon: Icon(SpotubeIcons.trash, color: Colors.red[400]),
                  onPressed: () {
                    ref
                        .read(BlackListNotifier.provider.notifier)
                        .remove(filteredBlacklist.elementAt(index));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
