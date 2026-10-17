import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nebula_iptv/data/database/database_provider.dart';
import 'package:nebula_iptv/data/repositories/catalog_repository.dart';
import 'package:nebula_iptv/domain/models/catalog_item.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
    (ref) => CatalogRepository(ref.watch(databaseProvider)));
final homeCatalogProvider = StreamProvider.autoDispose<HomeCatalog>(
    (ref) => ref.watch(catalogRepositoryProvider).watchHome());
final myListCatalogProvider = StreamProvider.autoDispose<List<CatalogItem>>(
    (ref) => ref.watch(catalogRepositoryProvider).watchMyList());
final resumeCatalogProvider = StreamProvider.autoDispose<List<CatalogItem>>(
    (ref) => ref.watch(catalogRepositoryProvider).watchContinueWatching());
final relatedCatalogProvider = FutureProvider.autoDispose
    .family<List<CatalogItem>, CatalogItem>(
        (ref, item) => ref.watch(catalogRepositoryProvider).related(item));
