import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' hide Image;
import 'package:spotube/helpers/image-to-url-string.dart';
import 'package:spotube/hooks/useBreakpoints.dart';
import 'package:spotube/models/sideBarTiles.dart';
import 'package:spotube/provider/SpotifyDI.dart';

class Sidebar extends HookConsumerWidget {
  final int selectedIndex;
  final void Function(int) onSelectedIndexChanged;

  const Sidebar({
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    Key? key,
  }) : super(key: key);

  Widget _buildSmallLogo() {
    return Image.asset(
      "assets/spotube-logo.png",
      height: 50,
      width: 50,
    );
  }

  static void goToSettings(BuildContext context) {
    GoRouter.of(context).push("/settings");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakpoints = useBreakpoints();
    if (breakpoints.isSm) return Container();
    final extended = useState(false);
    final SpotifyApi spotify = ref.watch(spotifyProvider);

    useEffect(() {
      if (breakpoints.isMd && extended.value) {
        extended.value = false;
      } else if (breakpoints.isMoreThanOrEqualTo(Breakpoints.lg) &&
          !extended.value) {
        extended.value = true;
      }
      return null;
    });

    return NavigationRail(
      destinations: sidebarTileList
          .map(
            (e) => NavigationRailDestination(
              icon: Icon(e.icon),
              label: Text(
                e.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )
          .toList(),
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelectedIndexChanged,
      extended: extended.value,
      leading: extended.value
          ? Padding(
              padding: const EdgeInsets.only(left: 15),
              child: Row(children: [
                _buildSmallLogo(),
                const SizedBox(
                  width: 10,
                ),
                Text("Spotube", style: Theme.of(context).textTheme.headline4),
              ]),
            )
          : _buildSmallLogo(),
      trailing: FutureBuilder<User>(
        future: spotify.me.get(),
        builder: (context, snapshot) {
          var avatarImg = imageToUrlString(snapshot.data?.images,
              index: (snapshot.data?.images?.length ?? 1) - 1);
          return extended.value
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(avatarImg),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            snapshot.data?.displayName ?? "Guest",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () => goToSettings(context)),
                    ],
                  ))
              : InkWell(
                  onTap: () => goToSettings(context),
                  child: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(avatarImg),
                  ),
                );
        },
      ),
    );
  }
}
