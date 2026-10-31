import 'package:flutter/material.dart';

const institutionalNavy = Color(0xFF072E65);
const institutionalWine = Color(0xFF80053F);
const institutionalGold = Color(0xFFF2BD36);

class SchoolEmblem extends StatelessWidget {
  const SchoolEmblem({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Emblema provisional del colegio',
    child: Container(
      width: 64,
      height: 76,
      decoration: BoxDecoration(
        color: institutionalNavy,
        border: Border.all(color: institutionalGold, width: 3),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(26),
          top: Radius.circular(10),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, color: Colors.white, size: 28),
          Text(
            'MB',
            style: TextStyle(
              color: institutionalGold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class InstitutionalHeader extends StatelessWidget {
  const InstitutionalHeader({super.key, this.onBack, this.wine = false});
  final VoidCallback? onBack;
  final bool wine;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: wine
            ? [institutionalWine, const Color(0xFF480B34)]
            : [institutionalNavy, const Color(0xFF097ACA)],
      ),
      border: const Border(
        bottom: BorderSide(color: institutionalGold, width: 5),
      ),
    ),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Volver al inicio'),
              ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SchoolEmblem(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I.E. Micaela Bastidas Puyucahua',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tamburco · Abancay · Apurímac',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Formando jóvenes con valores,\npara un mejor futuro',
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class InstitutionalFooter extends StatelessWidget {
  const InstitutionalFooter({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(
      color: institutionalNavy,
      border: Border(top: BorderSide(color: institutionalGold, width: 4)),
    ),
    child: const Column(
      children: [
        Icon(Icons.menu_book_outlined, color: Colors.white, size: 30),
        SizedBox(height: 10),
        Text(
          'Juntos construimos una mejor educación',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontStyle: FontStyle.italic,
            fontSize: 17,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'I.E. Micaela Bastidas Puyucahua',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}
