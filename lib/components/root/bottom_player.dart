import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent_ui;
import 'package:platform_ui/platform_ui.dart';
import 'package:spotube/collections/assets.gen.dart';
import 'package:spotube/components/player/player_actions.dart';
import 'package:spotube/components/player/player_overlay.dart';
import 'package:spotube/components/player/player_track_details.dart';
import 'package:spotube/components/player/player_controls.dart';
import 'package:spotube/hooks/use_breakpoints.dart';
import 'package:spotube/hooks/use_platform_property.dart';
import 'package:spotube/models/logger.dart';
import 'package:flutter/material.dart';
import 'package:spotube/provider/playlist_queue_provider.dart';
import 'package:spotube/provider/user_preferences_provider.dart';
import 'package:spotube/utils/type_conversion_utils.dart';

class BottomPlayer extends HookConsumerWidget {
  BottomPlayer({Key? key}) : super(key: key);

  final logger = getLogger(BottomPlayer);
  @override
  Widget build(BuildContext context, ref) {
    final playlist = ref.watch(PlaylistQueueNotifier.provider);
    final layoutMode =
        ref.watch(userPreferencesProvider.select((s) => s.layoutMode));

    final breakpoint = useBreakpoints();

    String albumArt = useMemoized(
      () => playlist?.activeTrack.album?.images?.isNotEmpty == true
          ? TypeConversionUtils.image_X_UrlString(
              playlist?.activeTrack.album?.images,
              index: (playlist?.activeTrack.album?.images?.length ?? 1) - 1,
              placeholder: ImagePlaceholder.albumArt,
            )
          : Assets.albumPlaceholder.path,
      [playlist?.activeTrack.album?.images],
    );

    // returning an empty non spacious Container as the overlay will take
    // place in the global overlay stack aka [_entries]
    if (layoutMode == LayoutMode.compact ||
        (breakpoint.isLessThanOrEqualTo(Breakpoints.md) &&
            layoutMode == LayoutMode.adaptive)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8, top: 0),
        child: PlayerOverlay(albumArt: albumArt),
      );
    }

    final backgroundColor = usePlatformProperty<Color?>(
      (context) => PlatformProperty(
        android: Theme.of(context).backgroundColor,
        ios: CupertinoTheme.of(context).scaffoldBackgroundColor,
        macos: MacosTheme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.blueGrey[50],
        linux: Theme.of(context).backgroundColor,
        windows: fluent_ui.FluentTheme.maybeOf(context)?.micaBackgroundColor,
      ),
    );

    final border = usePlatformProperty<BoxBorder?>(
      (context) => PlatformProperty(
        android: null,
        ios: Border(
          top: BorderSide(
            color: PlatformTheme.of(context).borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        macos: Border(
          top: BorderSide(
            color: PlatformTheme.of(context).borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        linux: Border(
          top: BorderSide(
            color: PlatformTheme.of(context).borderColor ?? Colors.transparent,
            width: 1,
          ),
        ),
        windows: null,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
      ),
      child: Material(
        type: MaterialType.transparency,
        textStyle: PlatformTheme.of(context).textTheme!.body!,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(child: PlayerTrackDetails(albumArt: albumArt)),
            // controls
            Flexible(
              flex: 3,
              child: PlayerControls(),
            ),
            // add to saved tracks
            Expanded(
              flex: 1,
              child: Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                children: [
                  Container(
                    height: 20,
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: HookBuilder(builder: (context) {
                      final volumeState = ref.watch(VolumeProvider.provider);
                      final volumeNotifier =
                          ref.watch(VolumeProvider.provider.notifier);
                      final volume = useState(volumeState);

                      useEffect(() {
                        if (volume.value != volumeState) {
                          volume.value = volumeState;
                        }
                        return null;
                      }, [volumeState]);

                      return Listener(
                        onPointerSignal: (event) async {
                          if (event is PointerScrollEvent) {
                            if (event.scrollDelta.dy > 0) {
                              final value = volume.value - .2;
                              volumeNotifier.setVolume(value < 0 ? 0 : value);
                            } else {
                              final value = volume.value + .2;
                              volumeNotifier.setVolume(value > 1 ? 1 : value);
                            }
                          }
                        },
                        child: PlatformSlider(
                          min: 0,
                          max: 1,
                          value: volume.value,
                          onChanged: (v) {
                            volume.value = v;
                          },
                          onChangeEnd: volumeNotifier.setVolume,
                        ),
                      );
                    }),
                  ),
                  PlayerActions()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
