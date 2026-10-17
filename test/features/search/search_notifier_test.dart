import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nebula_iptv/data/repositories/search_repository.dart';
import 'package:nebula_iptv/features/search/providers/search_provider.dart';

class DelayedSearch implements SearchRepository {
  final local = <String, Completer<SearchResults>>{};
  final remote = <String, Completer<SearchResults?>>{};
  @override
  Future<SearchResults> searchLocal(String query) =>
    (local[query] = Completer<SearchResults>()).future;
  @override
  Future<SearchResults?> searchRemote(String query) =>
    (remote[query] = Completer<SearchResults?>()).future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
SearchResults result(String query) => SearchResults(query: query, vod: [
  SearchResultItem(id: 1, playlistId: 1, name: query, sourceType: 'vod'),
]);
void main() {
  testWidgets('local results arrive before remote; previous query cannot overwrite', (tester) async {
    final repository = DelayedSearch();
    final notifier = SearchNotifier(repository);
    addTearDown(notifier.dispose);
    notifier.updateQuery('antiga');
    await tester.pump(const Duration(milliseconds: 221));
    repository.local['antiga']!.complete(result('antiga'));
    await tester.pump();
    expect(notifier.state.results!.vod.single.name, 'antiga');
    expect(notifier.state.isSearching, isFalse);
    notifier.updateQuery('nova');
    await tester.pump(const Duration(milliseconds: 221));
    repository.local['nova']!.complete(result('nova'));
    await tester.pump();
    repository.remote['antiga']!.complete(result('atrasada'));
    await tester.pump();
    expect(notifier.state.results!.vod.single.name, 'nova');
    repository.remote['nova']!.complete(null);
    await tester.pump();
  });
  testWidgets('clearing text invalidates a pending local search', (tester) async {
    final repository = DelayedSearch();
    final notifier = SearchNotifier(repository);
    addTearDown(notifier.dispose);
    notifier.updateQuery('filme');
    await tester.pump(const Duration(milliseconds: 221));
    notifier.updateQuery('');
    repository.local['filme']!.complete(result('filme'));
    await tester.pump();
    expect(notifier.state.query, isEmpty);
    expect(notifier.state.results!.isEmpty, isTrue);
    expect(repository.remote, isEmpty);
  });
  testWidgets('error is explicit and dispose ignores a late response', (tester) async {
    final repository = DelayedSearch();
    final notifier = SearchNotifier(repository);
    notifier.updateQuery('erro');
    await tester.pump(const Duration(milliseconds: 221));
    repository.local['erro']!.completeError(StateError('offline'));
    await tester.pump();
    expect(notifier.state.errorMessage, isNotNull);
    notifier.updateQuery('outra');
    await tester.pump(const Duration(milliseconds: 221));
    notifier.dispose();
    repository.local['outra']!.complete(result('outra'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
