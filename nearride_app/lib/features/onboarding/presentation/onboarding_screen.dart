import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const preferenceKey = 'onboarding_complete';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;

  static const pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.near_me_outlined,
      title: 'Find a ride nearby',
      description:
          'Discover cars, vans, bikes and more around you. Filter by vehicle type and search within the distance that works for you.',
      accent: Color(0xffd7f2e9),
    ),
    _OnboardingPage(
      icon: Icons.verified_user_outlined,
      title: 'Connect with confidence',
      description:
          'Explore clear listing details, save useful options and contact independent providers directly to confirm your trip.',
      accent: Color(0xffffe9c7),
    ),
    _OnboardingPage(
      icon: Icons.add_road_outlined,
      title: 'List your vehicle',
      description:
          'Have a vehicle or driving service? Create a provider profile, publish your listing and manage your availability in one place.',
      accent: Color(0xffdfe8ff),
    ),
  ];

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(OnboardingScreen.preferenceKey, true);
    if (mounted) context.go('/');
  }

  void next() {
    if (page == pages.length - 1) {
      finish();
      return;
    }
    controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Icon(Icons.route, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'NearRide',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: pages.length,
                onPageChanged: (value) => setState(() => page = value),
                itemBuilder: (context, index) => _PageContent(pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: index == page ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color:
                        index == page ? colors.primary : colors.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: next,
                  icon: Icon(page == pages.length - 1
                      ? Icons.check
                      : Icons.arrow_forward),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(page == pages.length - 1
                        ? 'Start exploring'
                        : 'Continue'),
                  ),
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('By continuing, you agree to our '),
                TextButton(
                  onPressed: () => context.push('/terms'),
                  child: const Text('Terms'),
                ),
                const Text('and'),
                TextButton(
                  onPressed: () => context.push('/privacy'),
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent(this.page);

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: page.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(page.icon, size: 94, color: const Color(0xff174f45)),
            ),
            const SizedBox(height: 44),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
}
