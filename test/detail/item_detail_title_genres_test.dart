import 'package:flutter_test/flutter_test.dart';

import 'package:moonfin/data/models/aggregated_item.dart';
import 'package:moonfin/ui/navigation/destinations.dart';
import 'package:moonfin/ui/screens/detail/item_detail_screen.dart';

void main() {
  test('detail title metadata keeps every genre', () {
    const genres = [
      'Genre One',
      'Genre Two',
      'Genre Three',
      'Genre Four',
      'Genre Five',
    ];
    const item = AggregatedItem(
      id: 'movie-1',
      serverId: 'server-1',
      rawData: {
        'Id': 'movie-1',
        'Name': 'Movie',
        'Type': 'Movie',
        'Genres': genres,
      },
    );

    expect(detailTitleGenres(item), genres);
  });

  test('advanced filter route carries detail genres and year', () {
    final location = Destinations.advancedFilterWith(
      genres: const ['Drama', 'Science Fiction'],
      year: 2024,
    );
    final uri = Uri.parse(location);

    expect(uri.path, Destinations.advancedFilter);
    expect(uri.queryParametersAll['genre'], const ['Drama', 'Science Fiction']);
    expect(uri.queryParametersAll['year'], const ['2024']);
  });
}
