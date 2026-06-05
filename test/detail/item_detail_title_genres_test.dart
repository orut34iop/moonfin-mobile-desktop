import 'package:flutter_test/flutter_test.dart';

import 'package:moonfin/data/models/aggregated_item.dart';
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
}
