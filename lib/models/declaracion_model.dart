
class DeclaracionModel {
  String id;
  String usuarioId;
  String nombreFuncionario;
  String identificacion;
  String telefono;
  String correo;
  String unidad;
  String periodo;
  String estado;
  DateTime fechaCreacion;

  DeclaracionModel({
    required this.id,
    required this.usuarioId,
    required this.nombreFuncionario,
    required this.identificacion,
    required this.telefono,
    required this.correo,
    required this.unidad,
    required this.periodo,
    required this.estado,
    required this.fechaCreacion,
  });

  // Convierte los datos a un mapa para Firebase
  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'nombreFuncionario': nombreFuncionario,
      'identificacion': identificacion,
      'telefono': telefono,
      'correo': correo,
      'unidad': unidad,
      'periodo': periodo,
      'estado': estado,
      'fechaCreacion': fechaCreacion,
    };
  }

  // Convierte los datos de Firebase a un objeto
  factory DeclaracionModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return DeclaracionModel(
      id: id,
      usuarioId: map['usuarioId'] ?? '',
      nombreFuncionario: map['nombreFuncionario'] ?? '',
      identificacion: map['identificacion'] ?? '',
      telefono: map['telefono'] ?? '',
      correo: map['correo'] ?? '',
      unidad: map['unidad'] ?? '',
      periodo: map['periodo'] ?? '',
      estado: map['estado'] ?? 'BORRADOR',
      fechaCreacion: map['fechaCreacion'] is DateTime
          ? map['fechaCreacion']
          : (map['fechaCreacion'] as dynamic)?.toDate() ??
              DateTime.now(),
    );
  }
}
