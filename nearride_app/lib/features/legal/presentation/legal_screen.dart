import 'package:flutter/material.dart';

enum LegalDocument { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  static const _privacySections = <_LegalSection>[
    _LegalSection(
      'Information we collect',
      'We collect account details you provide, such as your name, email, phone number and profile photo. If you create a listing, we also process vehicle, provider and listing information.',
    ),
    _LegalSection(
      'Location information',
      'With your permission, NearRide uses your approximate location to show nearby listings and calculate distance. Precise listing coordinates are not shown publicly.',
    ),
    _LegalSection(
      'How we use information',
      'We use information to operate and secure the marketplace, show relevant listings, enable favourites and contact actions, improve the service, prevent abuse and respond to support requests.',
    ),
    _LegalSection(
      'Sharing and visibility',
      'Public profile and listing details may be visible to other users. Contact details are shared when needed to connect users with providers. We may also disclose information when required by law or to protect users and the service.',
    ),
    _LegalSection(
      'Storage and security',
      'We use reasonable technical and organisational safeguards. No online service is completely secure, so please use a strong password and do not share sensitive information in listing descriptions.',
    ),
    _LegalSection(
      'Your choices',
      'You can update your profile, control location permission and request access, correction or deletion of your personal information. Some records may be retained where legally required or needed for safety and fraud prevention.',
    ),
    _LegalSection(
      'Contact us',
      'For privacy questions or requests, contact the NearRide support team through the contact details published in the app or official NearRide channels.',
    ),
  ];

  static const _termsSections = <_LegalSection>[
    _LegalSection(
      'Using NearRide',
      'You must provide accurate information, keep your account secure and use NearRide only for lawful purposes. You are responsible for activity performed through your account.',
    ),
    _LegalSection(
      'Marketplace role',
      'NearRide helps users discover independent vehicle owners and drivers. NearRide does not operate vehicles, employ providers, set prices or act as a party to agreements between users and providers.',
    ),
    _LegalSection(
      'Listings and providers',
      'Providers are responsible for the accuracy of listings, lawful vehicle operation, licences, insurance, pricing and service delivery. NearRide may review, pause or remove listings that breach these terms.',
    ),
    _LegalSection(
      'Bookings and payments',
      'Availability, price, route, payment and cancellation terms must be confirmed directly with the provider. Unless expressly stated in the app, NearRide does not collect or guarantee payments.',
    ),
    _LegalSection(
      'Safety',
      'Verify the provider, vehicle, licence, insurance, condition and agreed terms before travel. Do not proceed if something feels unsafe. In an emergency, contact the appropriate local emergency service.',
    ),
    _LegalSection(
      'Prohibited conduct',
      'Do not post false or unlawful content, impersonate others, harass users, misuse personal information, bypass security, interfere with the service or use NearRide for fraud or illegal transport.',
    ),
    _LegalSection(
      'Liability and changes',
      'The service is provided on an as-available basis. To the extent permitted by law, NearRide is not responsible for independent providers or transactions between users. We may update the service and these terms as it evolves.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    final title = privacy ? 'Privacy Policy' : 'Terms & Conditions';
    final sections = privacy ? _privacySections : _termsSections;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  privacy ? Icons.shield_outlined : Icons.handshake_outlined,
                  size: 38,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  privacy
                      ? 'How NearRide handles and protects your information.'
                      : 'The ground rules for using the NearRide marketplace.',
                  style: TextStyle(color: colors.onPrimaryContainer),
                ),
                const SizedBox(height: 12),
                Text(
                  'Effective: 5 August 2026',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...sections.indexed.map(
            (entry) => _SectionCard(
              number: entry.$1 + 1,
              section: entry.$2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review this document periodically. Continued use of NearRide after an update means you accept the revised document.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.number, required this.section});

  final int number;
  final _LegalSection section;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Text('$number'),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(section.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _LegalSection {
  const _LegalSection(this.title, this.body);

  final String title;
  final String body;
}
