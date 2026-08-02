import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/services/token_store.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/listings/data/listing_repository.dart';

final tokenStoreProvider = Provider((_) => const TokenStore());
final apiProvider =
    Provider((ref) => ApiClient(ref.read(tokenStoreProvider)));
final authServiceProvider = Provider(
  (ref) => AuthService(
    ref.read(apiProvider),
    ref.read(tokenStoreProvider),
  ),
);
final listingRepositoryProvider =
    Provider((ref) => ListingRepository(ref.read(apiProvider)));
