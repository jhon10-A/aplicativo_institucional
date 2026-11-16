/// Comunicado del colegio dirigido al apoderado.
class GuardianAnnouncement {
  const GuardianAnnouncement({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.autor,
    required this.fecha,
  });

  final int id;
  final String titulo;
  final String contenido;
  final String autor;

  /// Fecha de publicación en formato aaaa-mm-dd.
  final String fecha;

  factory GuardianAnnouncement.fromJson(Map<String, dynamic> json) =>
      GuardianAnnouncement(
        id: json['id'] as int,
        titulo: json['titulo'] as String,
        contenido: json['contenido'] as String,
        autor: json['autor'] as String,
        fecha: json['fecha'] as String,
      );
}
