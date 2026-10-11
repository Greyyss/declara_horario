
class TrabajoExternoModel {
  String id;
  String institucion;
  String cargo;
  double jornada;
  DateTime fechaInicio;
  DateTime fechaFin;
  List<Map<String, dynamic>> horarios;

  TrabajoExternoModel({
    required this.id,
    required this.institucion,
    required this.cargo,
    required this.jornada,
    required this.fechaInicio,
    required this.fechaFin,
    required this.horarios,
  });

  Map<String, dynamic> toMap() {
    return {
      'institucion': institucion,
      'cargo': cargo,
      'jornada': jornada,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'horarios': horarios,
    };
  }

  factory TrabajoExternoModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TrabajoExternoModel(
      id: id,
      institucion: map['institucion'] ?? '',
      cargo: map['cargo'] ?? '',
      jornada: (map['jornada'] as num?)?.toDouble() ?? 0,
      fechaInicio:
          (map['fechaInicio'] as dynamic)?.toDate() ?? DateTime.now(),
      fechaFin:
          (map['fechaFin'] as dynamic)?.toDate() ?? DateTime.now(),
      horarios: List<Map<String, dynamic>>.from(
        (map['horarios'] as List<dynamic>? ?? []).map(
          (horario) => Map<String, dynamic>.from(horario),
        ),
      ),
    );
  }
}
