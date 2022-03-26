import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:spotube/components/Player/PlayerActions.dart';
import 'package:spotube/components/Player/PlayerControls.dart';
import 'package:spotube/components/Shared/PageWindowTitleBar.dart';
import 'package:spotube/helpers/artists-to-clickable-artists.dart';
import 'package:spotube/helpers/image-to-url-string.dart';
import 'package:spotube/hooks/useBreakpoints.dart';
import 'package:spotube/hooks/usePaletteColor.dart';
import 'package:spotube/provider/Playback.dart';

class PlayerView extends HookConsumerWidget {
  const PlayerView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final currentTrack = ref.watch(playbackProvider.select(
      (value) => value.currentTrack,
    ));
    final breakpoint = useBreakpoints();

    useEffect(() {
      if (breakpoint.isMoreThan(Breakpoints.md)) {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          GoRouter.of(context).pop();
        });
      }
      return null;
    }, [breakpoint]);

    String albumArt = useMemoized(
      () => imageToUrlString(
        currentTrack?.album?.images,
        index: (currentTrack?.album?.images?.length ?? 1) - 1,
      ),
      [currentTrack?.album?.images],
    );

    final PaletteColor paletteColor = usePaletteColor(context, albumArt);

    return SafeArea(
      child: Scaffold(
        appBar: const PageWindowTitleBar(
          leading: BackButton(),
        ),
        backgroundColor: paletteColor.color,
        body: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    currentTrack?.name ?? "Not playing",
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headline5?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: paletteColor.titleTextColor,
                        ),
                  ),
                  artistsToClickableArtists(
                    currentTrack?.artists ?? [],
                    textStyle: Theme.of(context).textTheme.headline6!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: paletteColor.bodyTextColor,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            HookBuilder(builder: (context) {
              final ticker = useSingleTickerProvider();
              final controller = useAnimationController(
                duration: const Duration(seconds: 10),
                vsync: ticker,
              )..repeat();
              return RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(controller),
                child: CircleAvatar(
                  backgroundImage: CachedNetworkImageProvider(
                    albumArt,
                    cacheKey: albumArt,
                  ),
                  radius: MediaQuery.of(context).size.width *
                      (breakpoint.isSm ? 0.4 : 0.3),
                ),
              );
            }),
            const Spacer(),
            const PlayerActions(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
            PlayerControls(iconColor: paletteColor.bodyTextColor),
          ],
        ),
      ),
    );
  }
}
