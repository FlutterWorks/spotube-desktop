import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:platform_ui/platform_ui.dart';
import 'package:spotube/collections/spotube_icons.dart';
import 'package:spotube/components/root/sidebar.dart';
import 'package:spotube/provider/spotify_provider.dart';

class PlaylistCreateDialog extends HookConsumerWidget {
  const PlaylistCreateDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final spotify = ref.watch(spotifyProvider);

    return SizedBox(
      width: 200,
      child: PlatformTextButton(
        onPressed: () {
          showPlatformAlertDialog(
            context,
            builder: (context) {
              return HookBuilder(builder: (context) {
                final playlistName = useTextEditingController();
                final description = useTextEditingController();
                final public = useState(false);
                final collaborative = useState(false);
                final client = useQueryClient();
                final navigator = Navigator.of(context);

                onCreate() async {
                  if (playlistName.text.isEmpty) return;
                  final me = await spotify.me.get();
                  await spotify.playlists.createPlaylist(
                    me.id!,
                    playlistName.text,
                    collaborative: collaborative.value,
                    public: public.value,
                    description: description.text,
                  );
                  await client
                      .getQuery(
                        "current-user-playlists",
                      )
                      ?.refresh();
                  navigator.pop();
                }

                return PlatformAlertDialog(
                  macosAppIcon: Sidebar.brandLogo(),
                  title: const PlatformText("Create a Playlist"),
                  primaryActions: [
                    PlatformBuilder(
                      fallback: PlatformBuilderFallback.android,
                      android: (context, _) {
                        return PlatformFilledButton(
                          onPressed: onCreate,
                          child: const Text("Create"),
                        );
                      },
                      ios: (context, data) {
                        return CupertinoDialogAction(
                          isDefaultAction: true,
                          onPressed: onCreate,
                          child: const Text("Create"),
                        );
                      },
                    ),
                  ],
                  secondaryActions: [
                    PlatformBuilder(
                      fallback: PlatformBuilderFallback.android,
                      android: (context, _) {
                        return PlatformFilledButton(
                          isSecondary: true,
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        );
                      },
                      ios: (context, data) {
                        return CupertinoDialogAction(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          isDestructiveAction: true,
                          child: const Text("Cancel"),
                        );
                      },
                    ),
                  ],
                  content: Container(
                    width: MediaQuery.of(context).size.width,
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        PlatformTextField(
                          controller: playlistName,
                          placeholder: "Name of the playlist",
                          label: "Playlist Name",
                        ),
                        const SizedBox(height: 10),
                        PlatformTextField(
                          controller: description,
                          placeholder: "Description...",
                          keyboardType: TextInputType.multiline,
                          maxLines: 5,
                        ),
                        const SizedBox(height: 10),
                        PlatformCheckbox(
                          value: public.value,
                          label: const PlatformText("Public"),
                          onChanged: (val) => public.value = val ?? false,
                        ),
                        const SizedBox(height: 10),
                        PlatformCheckbox(
                          value: collaborative.value,
                          label: const PlatformText("Collaborative"),
                          onChanged: (val) =>
                              collaborative.value = val ?? false,
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          );
        },
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(vertical: 100),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(SpotubeIcons.addFilled, size: 40),
            PlatformText("Create Playlist", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
