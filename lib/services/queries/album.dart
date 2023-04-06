import 'package:catcher/catcher.dart';
import 'package:fl_query/fl_query.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spotify/spotify.dart';
import 'package:spotube/hooks/use_spotify_infinite_query.dart';
import 'package:spotube/hooks/use_spotify_query.dart';
import 'package:spotube/provider/user_preferences_provider.dart';

class AlbumQueries {
  const AlbumQueries();

  Query<Iterable<AlbumSimple>, dynamic> ofMine(WidgetRef ref) {
    return useSpotifyQuery<Iterable<AlbumSimple>, dynamic>(
      "current-user-albums",
      (spotify) {
        return spotify.me.savedAlbums().all();
      },
      ref: ref,
    );
  }

  Query<List<TrackSimple>, dynamic> tracksOf(
    WidgetRef ref,
    String albumId,
  ) {
    return useSpotifyQuery<List<TrackSimple>, dynamic>(
      "album-tracks/$albumId",
      (spotify) {
        return spotify.albums
            .getTracks(albumId)
            .all()
            .then((value) => value.toList());
      },
      ref: ref,
    );
  }

  Query<bool, dynamic> isSavedForMe(
    WidgetRef ref,
    String album,
  ) {
    return useSpotifyQuery<bool, dynamic>(
      "is-saved-for-me/$album",
      (spotify) {
        return spotify.me.isSavedAlbums([album]).then((value) => value.first);
      },
      ref: ref,
    );
  }

  InfiniteQuery<Page<AlbumSimple>, dynamic, int> newReleases(WidgetRef ref) {
    final market = ref
        .watch(userPreferencesProvider.select((s) => s.recommendationMarket));

    return useSpotifyInfiniteQuery<Page<AlbumSimple>, dynamic, int>(
      "new-releases",
      (pageParam, spotify) async {
        try {
          final albums = await spotify.browse
              .getNewReleases(country: market)
              .getPage(5, pageParam);

          return albums;
        } catch (e, stack) {
          Catcher.reportCheckedError(e, stack);
          rethrow;
        }
      },
      ref: ref,
      initialPage: 0,
      nextPage: (lastPage, lastPageData) {
        if (lastPageData.isLast) {
          return null;
        }
        return lastPageData.nextOffset;
      },
    );
  }
}
