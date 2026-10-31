import 'package:flutter/material.dart';

import '../access_profile.dart';
import '../widgets/access_card.dart';
import '../widgets/institutional_brand.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.onAccess,
    required this.onTechnology,
  });
  final ValueChanged<AccessProfile> onAccess;
  final VoidCallback onTechnology;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF0F7FD),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const InstitutionalHeader(),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '¡Bienvenidos!',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: institutionalNavy,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nuestra institución, un espacio para crecer, aprender y soñar.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 340 ? 2 : 1;
                          final width =
                              (constraints.maxWidth - (columns - 1) * 14) /
                              columns;
                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              for (final access in AccessProfile.values)
                                SizedBox(
                                  width: width,
                                  child: AccessCard(
                                    label: access.label,
                                    description: access.description,
                                    icon: access.icon,
                                    color: access.color,
                                    onTap: () => onAccess(access),
                                  ),
                                ),
                              SizedBox(
                                width: width,
                                child: AccessCard(
                                  label: 'Tecnología',
                                  description: 'Aprendamos más con tecnología',
                                  icon: Icons.devices_outlined,
                                  color: const Color(0xFFAD5709),
                                  onTap: onTechnology,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const InstitutionalFooter(),
          ],
        ),
      ),
    ),
  );
}
