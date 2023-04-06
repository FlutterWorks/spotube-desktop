import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/components/shared/playbutton_card.dart';
import 'package:spotube/hooks/use_breakpoint_value.dart';
import 'package:spotube/provider/playlist_queue_provider.dart';
import 'package:spotube/provider/spotify_provider.dart';
import 'package:spotube/utils/service_utils.dart';
import 'package:spotube/utils/type_conversion_utils.dart';

enum AlbumType {
  album,
  single,
  compilation;

  factory AlbumType.from(String? type) {
    switch (type) {
      case "album":
        return AlbumType.album;
      case "single":
        return AlbumType.single;
      case "compilation":
        return AlbumType.compilation;
      default:
        return AlbumType.album;
    }
  }

  String get formatted => name.replaceFirst(name[0], name[0].toUpperCase());
}

class AlbumCard extends HookConsumerWidget {
  final Album album;
  final PlaybuttonCardViewType viewType;
  const AlbumCard(
    this.album, {
    Key? key,
    this.viewType = PlaybuttonCardViewType.square,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final playlist = ref.watch(PlaylistQueueNotifier.provider);
    final playing = useStream(PlaylistQueueNotifier.playing).data ??
        PlaylistQueueNotifier.isPlaying;
    final playlistNotifier = ref.watch(PlaylistQueueNotifier.notifier);
    final queryClient = useQueryClient();
    final query = queryClient
        .getQuery<List<TrackSimple>, dynamic>("album-tracks/${album.id}");
    bool isPlaylistPlaying = useMemoized(
      () =>
          playlistNotifier.isPlayingPlaylist(query?.data ?? album.tracks ?? []),
      [playlistNotifier, query?.data, album.tracks],
    );
    final int marginH =
        useBreakpointValue(sm: 10, md: 15, lg: 20, xl: 20, xxl: 20);

    final updating = useState(false);
    final spotify = ref.watch(spotifyProvider);

    return PlaybuttonCard(
        imageUrl: TypeConversionUtils.image_X_UrlString(
          album.images,
          placeholder: ImagePlaceholder.collection,
        ),
        viewType: viewType,
        margin: EdgeInsets.symmetric(horizontal: marginH.toDouble()),
        isPlaying: isPlaylistPlaying,
        isLoading: isPlaylistPlaying && playlist?.isLoading == true,
        title: album.name!,
        description:
            "${AlbumType.from(album.albumType!).formatted} • ${TypeConversionUtils.artists_X_String<ArtistSimple>(album.artists ?? [])}",
        onTap: () {
          ServiceUtils.navigate(context, "/album/${album.id}", extra: album);
        },
        onPlaybuttonPressed: () async {
          updating.value = true;
          try {
            if (isPlaylistPlaying && playing) {
              return playlistNotifier.pause();
            } else if (isPlaylistPlaying && !playing) {
              return playlistNotifier.resume();
            }

            await playlistNotifier.loadAndPlay(album.tracks
                    ?.map((e) =>
                        TypeConversionUtils.simpleTrack_X_Track(e, album))
                    .toList() ??
                []);
          } finally {
            updating.value = false;
          }
        },
        onAddToQueuePressed: () async {
          if (isPlaylistPlaying) {
            return;
          }

          updating.value = true;
          try {
            final fetchedTracks =
                await queryClient.fetchQuery<List<TrackSimple>, SpotifyApi>(
              "album-tracks/${album.id}",
              () {
                return spotify.albums
                    .getTracks(album.id!)
                    .all()
                    .then((value) => value.toList());
              },
            ).then(
              (tracks) => tracks
                  ?.map(
                      (e) => TypeConversionUtils.simpleTrack_X_Track(e, album))
                  .toList(),
            );

            if (fetchedTracks == null || fetchedTracks.isEmpty) return;
            playlistNotifier.add(
              fetchedTracks,
            );
            if (context.mounted) {
              final snackbar = SnackBar(
                content: Text("Added ${album.tracks?.length} tracks to queue"),
                action: SnackBarAction(
                  label: "Undo",
                  onPressed: () {
                    playlistNotifier.remove(fetchedTracks);
                  },
                ),
              );
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(snackbar);
            }
          } finally {
            updating.value = false;
          }
        });
  }
}
