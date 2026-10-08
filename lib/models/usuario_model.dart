class UsuarioModel {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  factory UsuarioModel.fromMap(String uid, Map<String, dynamic> datos) {
    return UsuarioModel(
      uid: uid,
      nombre: datos['nombre'] ?? '',
      correo: datos['correo'] ?? '',
      rol: datos['rol'] ?? 'declarante',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
    };
  }
}