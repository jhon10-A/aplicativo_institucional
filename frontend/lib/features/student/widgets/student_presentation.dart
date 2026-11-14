import 'package:flutter/material.dart';

import '../student_theme.dart';

class StudentSectionHeading extends StatelessWidget {
  const StudentSectionHeading({
    super.key,
    required this.title,
    required this.icon,
  });
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: studentWine.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: studentWine, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class StudentPreviewCard extends StatelessWidget {
  const StudentPreviewCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onOpen,
    required this.child,
    this.actionLabel = 'Ver todos',
  });
  final String title;
  final IconData icon;
  final VoidCallback? onOpen;
  final String actionLabel;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compact = box.maxWidth < 480;
      return Card(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: studentWine.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      icon,
                      color: studentNavy,
                      size: compact ? 18 : 22,
                    ),
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: compact ? 80 : double.infinity,
                    ),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 4 : 10,
                        ),
                        minimumSize: const Size(40, 40),
                      ),
                      onPressed: onOpen,
                      child: Text(
                        actionLabel,
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: compact ? 11 : 12),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 8),
              child,
            ],
          ),
        ),
      );
    },
  );
}

class StudentHeader extends StatelessWidget {
  const StudentHeader({
    super.key,
    required this.compact,
    required this.onLogout,
  });
  final bool compact;
  final VoidCallback onLogout;
  Widget get emblem => Image.asset(
    'assets/student/escudo.png',
    width: compact ? 36 : 56,
    height: compact ? 46 : 68,
    semanticLabel: 'Escudo de la I.E. Micaela Bastidas',
  );
  Widget logout(BuildContext context) => MediaQuery.sizeOf(context).width < 700
      ? IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
        )
      : TextButton.icon(
          onPressed: onLogout,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        );
  static const location = Text(
    'Tamburco · Abancay · Apurímac',
    style: TextStyle(color: Color(0xFFF4DCE7), fontSize: 11),
  );
  static const motto = Text(
    'Formando jóvenes con valores, para un mejor futuro',
    style: TextStyle(
      color: Color(0xFFF4DCE7),
      fontSize: 11,
      fontStyle: FontStyle.italic,
      height: 1.35,
    ),
  );
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(colors: [Color(0xFF790738), Color(0xFF470622)]),
      borderRadius: BorderRadius.vertical(bottom: Radius.elliptical(600, 22)),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 12 : 28,
      vertical: compact ? 8 : 16,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1160),
        child:
            compact &&
                (MediaQuery.sizeOf(context).width < 480 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2)
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      emblem,
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I.E. Micaela Bastidas Puyucahua',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      logout(context),
                    ],
                  ),
                  const SizedBox(height: 4),
                  location,
                  const SizedBox(height: 3),
                  motto,
                ],
              )
            : Row(
                children: [
                  emblem,
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 5),
                        location,
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(width: compact ? 140 : 235, child: motto),
                  const SizedBox(width: 20),
                  logout(context),
                ],
              ),
      ),
    ),
  );
}
