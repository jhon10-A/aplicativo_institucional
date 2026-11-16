import 'package:flutter/material.dart';

import '../guardian_theme.dart';

/// Encabezado institucional: escudo, nombre del colegio y cierre de sesión.
class GuardianHeader extends StatelessWidget {
  const GuardianHeader({super.key, required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [guardianWine, guardianWineDark]),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 28,
        vertical: compact ? 10 : 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Row(
            children: [
              Image.asset(
                'assets/institutional/escudo.png',
                width: compact ? 40 : 56,
                semanticLabel: 'Escudo de la I.E. Micaela Bastidas',
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'I.E. Micaela Bastidas Puyucahua',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 14 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tamburco · Abancay · Apurímac',
                      style: TextStyle(color: Color(0xFFF4DCE7), fontSize: 12),
                    ),
                    if (!compact)
                      const Text(
                        'Formando jóvenes con valores, para un mejor futuro',
                        style: TextStyle(
                          color: Color(0xFFF4DCE7),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (width < 520)
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                )
              else
                TextButton.icon(
                  onPressed: onLogout,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
