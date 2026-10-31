import 'package:flutter/material.dart';

import '../widgets/institutional_brand.dart';

class TechnologyPage extends StatelessWidget {
  const TechnologyPage({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            InstitutionalHeader(onBack: onBack),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 64),
              child: Column(
                children: [
                  Icon(
                    Icons.devices_outlined,
                    size: 72,
                    color: institutionalNavy,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tecnología',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aún no hay recursos publicados',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const InstitutionalFooter(),
          ],
        ),
      ),
    ),
  );
}
