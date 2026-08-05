import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'core/services/token_store.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/admin_listings_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/favourites/presentation/favourites_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/listings/presentation/listing_details_screen.dart';
import 'features/legal/presentation/legal_screen.dart';
import 'features/onboarding/presentation/launch_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/provider/presentation/provider_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/search/presentation/search_screen.dart';

final router = GoRouter(initialLocation: '/launch', routes: [
  GoRoute(path: '/launch', builder: (_, __) => const LaunchScreen()),
  GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
  GoRoute(
    path: '/privacy',
    builder: (_, __) => const LegalScreen(document: LegalDocument.privacy),
  ),
  GoRoute(
    path: '/terms',
    builder: (_, __) => const LegalScreen(document: LegalDocument.terms),
  ),
  GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
  GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
  GoRoute(
    path: '/favourites',
    redirect: (_, state) async {
      final accessToken = await const TokenStore().access();
      if (accessToken != null && accessToken.isNotEmpty) return null;
      return Uri(
        path: '/login',
        queryParameters: {'redirect': state.matchedLocation},
      ).toString();
    },
    builder: (_, __) => const FavouritesScreen(),
  ),
  GoRoute(
    path: '/login',
    builder: (_, state) => LoginScreen(
      redirectTo: state.uri.queryParameters['redirect'],
    ),
  ),
  GoRoute(
    path: '/register',
    builder: (_, state) => RegisterScreen(
      redirectTo: state.uri.queryParameters['redirect'],
    ),
  ),
  GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  GoRoute(
      path: '/listing/:id',
      builder: (_, state) =>
          ListingDetailsScreen(id: state.pathParameters['id']!)),
  GoRoute(
    path: '/provider',
    redirect: (_, state) async {
      final accessToken = await const TokenStore().access();
      if (accessToken != null && accessToken.isNotEmpty) return null;
      return Uri(
        path: '/login',
        queryParameters: {'redirect': state.matchedLocation},
      ).toString();
    },
    builder: (_, __) => const ProviderScreen(),
  ),
  GoRoute(
    path: '/admin/listings',
    redirect: (_, state) async {
      final accessToken = await const TokenStore().access();
      if (accessToken != null && accessToken.isNotEmpty) return null;
      return Uri(
        path: '/login',
        queryParameters: {'redirect': state.matchedLocation},
      ).toString();
    },
    builder: (_, __) => const AdminListingsScreen(),
  ),
]);

class NearRideApp extends StatelessWidget {
  const NearRideApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: AppConstants.name,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
      );
}
