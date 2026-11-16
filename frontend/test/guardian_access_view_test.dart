import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplicativo_institucional/access_profile.dart';
import 'package:aplicativo_institucional/auth.dart';
import 'package:aplicativo_institucional/features/guardian/guardian_access_view.dart';
import 'package:aplicativo_institucional/screens/login_page.dart';
import 'package:aplicativo_institucional/widgets/login_form.dart';

Widget _login({VoidCallback? onBack}) => MaterialApp(
  home: LoginPage(
    api: AuthApi(),
    access: AccessProfile.apoderado,
    onLogin: (_) {},
    onBack: onBack ?? () {},
  ),
);

void main() {
  testWidgets('el acceso de padres usa el portal con la identidad del colegio', (
    tester,
  ) async {
    await tester.pumpWidget(_login());
    await tester.pumpAndSettle();
    expect(find.byType(GuardianAccessView), findsOneWidget);
    expect(find.text('PORTAL INSTITUCIONAL'), findsOneWidget);
    expect(find.text('Padre de Familia'), findsOneWidget);
    expect(find.text('Ingresa a tu cuenta institucional'), findsOneWidget);
    expect(find.text('Tu apoyo\ntambién educa'), findsOneWidget);
    expect(
      tester.widget<LoginForm>(find.byType(LoginForm)).access,
      AccessProfile.apoderado,
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Regresar al menú principal vuelve al inicio', (tester) async {
    var back = false;
    await tester.pumpWidget(_login(onBack: () => back = true));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Regresar al menú principal'));
    await tester.tap(find.text('Regresar al menú principal'));
    expect(back, isTrue);
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('se adapta a $size con texto ampliado sin overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: _login(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
