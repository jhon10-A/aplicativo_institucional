class StudentGrade {
  StudentGrade.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      curso = json['curso'] as String,
      docente = json['docente'] as String,
      periodo = json['periodo'] as String,
      nivel = json['nivel'] as String,
      grado = json['grado'] as String,
      seccion = json['seccion'] as String,
      etapa = json['etapa'] as String,
      concepto = json['concepto'] as String,
      nota = (json['nota'] as num).toDouble(),
      observacion = json['observacion'] as String?,
      registradoEn = DateTime.parse(json['registradoEn'] as String);

  final int id;
  final String curso;
  final String docente;
  final String periodo;
  final String nivel;
  final String grado;
  final String seccion;
  final String etapa;
  final String concepto;
  final double nota;
  final String? observacion;
  final DateTime registradoEn;
}
