import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const verifiedInstitutionLocation = LatLng(-13.6219539, -72.8744841);
const verifiedInstitutionGoogleMapsUrl =
    'https://maps.app.goo.gl/mdfbYVYQVeHgnG5w6';

class OpenStreetMapView extends StatelessWidget {
  const OpenStreetMapView({
    super.key,
    required this.height,
    this.verifiedLocation,
  });

  final double height;
  final LatLng? verifiedLocation;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('open-street-map'),
    height: height,
    child: FlutterMap(
      options: MapOptions(
        initialCenter: verifiedLocation ?? verifiedInstitutionLocation,
        initialZoom: 17.5,
        minZoom: 3,
        maxZoom: 19,
        // Avoid accidentally panning away from the school with a one-finger
        // swipe. Keep pinch zoom and two-finger movement available.
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.all &
              ~InteractiveFlag.drag &
              ~InteractiveFlag.flingAnimation,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.aplicativo_institucional',
        ),
        if (verifiedLocation case final location?)
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 52,
                height: 58,
                child: Semantics(
                  label: 'I.E. Micaela Bastidas Puyucahua',
                  child: Container(
                    key: const Key('verified-school-marker'),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF2BD36),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFF800638),
                      size: 42,
                    ),
                  ),
                ),
              ),
            ],
          ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            key: const Key('open-street-map-attribution'),
            constraints: const BoxConstraints(maxWidth: 220),
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Tooltip(
              message: 'Ver la licencia de OpenStreetMap',
              child: InkWell(
                onTap: () => _openAttribution(context),
                child: const Text(
                  '© OpenStreetMap contributors',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, height: 1.2),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _openAttribution(BuildContext context) async {
    final opened = await launchUrl(
      Uri.https('www.openstreetmap.org', '/copyright'),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la licencia de OSM.')),
      );
    }
  }
}

class LocationHeaderIllustration extends StatelessWidget {
  const LocationHeaderIllustration({
    super.key,
    this.width = 88,
    this.height = 72,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size(width, height * .86),
          painter: const _LocationIllustrationPainter(),
        ),
        Positioned(
          right: width * .18,
          top: 0,
          child: Icon(
            Icons.location_on,
            color: const Color(0xFFD52B3F),
            size: height * .42,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: .16),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LocationIllustrationPainter extends CustomPainter {
  const _LocationIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paper = ui.Path()
      ..moveTo(size.width * .04, size.height * .57)
      ..lineTo(size.width * .24, size.height * .42)
      ..lineTo(size.width * .42, size.height * .5)
      ..lineTo(size.width * .61, size.height * .38)
      ..lineTo(size.width * .96, size.height * .55)
      ..lineTo(size.width * .91, size.height * .87)
      ..lineTo(size.width * .56, size.height * .75)
      ..lineTo(size.width * .32, size.height * .88)
      ..lineTo(size.width * .08, size.height * .75)
      ..close();
    canvas.drawPath(paper, Paint()..color = const Color(0xFFC9E7FA));

    final mountains = Paint()..color = const Color(0xFF67B6E9);
    for (final triangle in [
      [Offset(.08, .68), Offset(.27, .38), Offset(.46, .68)],
      [Offset(.34, .68), Offset(.57, .27), Offset(.81, .68)],
      [Offset(.58, .69), Offset(.78, .43), Offset(.97, .68)],
    ]) {
      final path = ui.Path()
        ..moveTo(size.width * triangle[0].dx, size.height * triangle[0].dy)
        ..lineTo(size.width * triangle[1].dx, size.height * triangle[1].dy)
        ..lineTo(size.width * triangle[2].dx, size.height * triangle[2].dy)
        ..close();
      canvas.drawPath(path, mountains);

      final peak = ui.Path()
        ..moveTo(size.width * triangle[1].dx, size.height * triangle[1].dy)
        ..lineTo(
          size.width * (triangle[1].dx - .06),
          size.height * (triangle[1].dy + .12),
        )
        ..lineTo(
          size.width * (triangle[1].dx + .07),
          size.height * (triangle[1].dy + .1),
        )
        ..close();
      canvas.drawPath(peak, Paint()..color = Colors.white);
    }

    final fold = Paint()
      ..color = const Color(0xFF9BCFEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width * .32, size.height * .48),
      Offset(size.width * .3, size.height * .87),
      fold,
    );
    canvas.drawLine(
      Offset(size.width * .62, size.height * .39),
      Offset(size.width * .58, size.height * .76),
      fold,
    );
  }

  @override
  bool shouldRepaint(covariant _LocationIllustrationPainter oldDelegate) =>
      false;
}
