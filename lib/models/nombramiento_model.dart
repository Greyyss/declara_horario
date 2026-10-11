
class NombramientoModel {
  String id;
  String lugarTrabajo;
  String cargo;
  double jornada;
  DateTime fechaInicio;
  DateTime fechaFin;
  List<Map<String, dynamic>> horarios;

  NombramientoModel({
    required this.id,
    required this.lugarTrabajo,
    required this.cargo,
    required this.jornada,
    required this.fechaInicio,
    required this.fechaFin,
    required this.horarios,
  });

  // Convierte el nombramiento a un mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'lugarTrabajo': lugarTrabajo,
      'cargo': cargo,
      'jornada': jornada,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'horarios': horarios,
    };
  }

  // Convierte los datos de Firebase a un nombramiento
  factory NombramientoModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return NombramientoModel(
      id: id,
      lugarTrabajo: map['lugarTrabajo'] ?? '',
      cargo: map['cargo'] ?? '',
      jornada: (map['jornada'] as num?)?.toDouble() ?? 0,
      fechaInicio: (map['fechaInicio'] as dynamic)?.toDate()
          ?? DateTime.now(),
      fechaFin: (map['fechaFin'] as dynamic)?.toDate()
          ?? DateTime.now(),
      horarios: List<Map<String, dynamic>>.from(
        (map['horarios'] as List<dynamic>? ?? []).map(
          (horario) => Map<String, dynamic>.from(horario),
        ),
      ),
    );
  }
}
