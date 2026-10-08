import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Usuario que tiene la sesión iniciada
  User? get usuarioActual => _auth.currentUser;

  // Iniciar sesión
  Future<User?> iniciarSesion(String correo, String contrasena) async {
    try {
      UserCredential resultado = await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );

      return resultado.user;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Obtener los datos y rol del usuario
  Future<Map<String, dynamic>?> obtenerDatosUsuario(String uid) async {
    DocumentSnapshot documento =
        await _firestore.collection('users').doc(uid).get();

    if (documento.exists) {
      return documento.data() as Map<String, dynamic>;
    }

    return null;
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}