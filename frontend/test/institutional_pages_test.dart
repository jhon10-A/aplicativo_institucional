import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/main.dart';
import 'package:aplicativo_institucional/features/institutional/institutional_page.dart';
import 'package:aplicativo_institucional/features/institutional/institutional_section.dart';
import 'package:aplicativo_institucional/features/institutional/student_access_view.dart';
import 'package:aplicativo_institucional/screens/login_page.dart';
import 'package:aplicativo_institucional/access_profile.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/widgets/login_form.dart';

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1440, 900),
  ]) {
    testWidgets('navega por las seis páginas públicas en $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final section in InstitutionalSection.values) {
        var returned = false;
        await tester.pumpWidget(
          MaterialApp(
            home: InstitutionalPage(
              key: ValueKey(section),
              section: section,
              onBack: () => returned = true,
              onSection: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(section.title), findsWidgets);
        for (final chip
            in tester
                .widgetList<ChoiceChip>(find.byType(ChoiceChip))
                .toList()) {
          final label = (chip.label as Text).data!;
          final finder = find.widgetWithText(ChoiceChip, label);
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        if (section == InstitutionalSection.location) {
          await tester.ensureVisible(find.byTooltip('Volver al inicio'));
          await tester.tap(find.byTooltip('Volver al inicio'));
        } else {
          await tester.ensureVisible(find.text('Volver al inicio'));
          await tester.tap(find.text('Volver al inicio'));
        }
        expect(returned, isTrue);
      }
    });
  }

  testWidgets('Inicio abre institución y regresa sin crear sesión', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nuestra Institución'));
    await tester.tap(find.text('Nuestra Institución'));
    await tester.pumpAndSettle();
    expect(find.byType(InstitutionalPage), findsOneWidget);
    await tester.ensureVisible(find.text('Volver al inicio'));
    await tester.tap(find.text('Volver al inicio'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Menú institucional'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('galería filtra sin inventar álbumes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: InstitutionalPage(
          section: InstitutionalSection.gallery,
          onBack: () {},
          onSection: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ceremonia');
    await tester.pumpAndSettle();
    expect(
      find.text('No hay álbumes publicados que coincidan con tu búsqueda.'),
      findsOneWidget,
    );
    expect(find.text('Sin álbumes publicados'), findsOneWidget);
  });

  for (final role in AccessProfile.values) {
    testWidgets('presentación del acceso ${role.role} conserva su formulario', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            api: AuthApi(),
            access: role,
            onLogin: (_) {},
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(StudentAccessView),
        role == AccessProfile.estudiante ? findsOneWidget : findsNothing,
      );
      expect(tester.widget<LoginForm>(find.byType(LoginForm)).access, role);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
