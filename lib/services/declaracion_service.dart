
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/declaracion_model.dart';
import '../models/nombramiento_model.dart';
import '../models/trabajo_externo_model.dart';
import 'validacion_horarios_service.dart';

class DeclaracionService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Prepara los datos de un evento de auditoría.
  Map<String, dynamic> crearEvento({
    required String accion,
    required String usuarioId,
    required int version,
    required String estadoAnterior,
    required String estadoNuevo,
    String observacion = '',
  }) {
    return {
      'evento': accion,
      'usuarioId': usuarioId,
      'fechaHora': FieldValue.serverTimestamp(),
      'version': version,
      'estadoAnterior': estadoAnterior,
      'estadoNuevo': estadoNuevo,
      'observacion': observacion,
    };
  }

  // Guarda una declaración nueva con su primera versión.
  Future<String> guardarDeclaracion({
    required String nombre,
    required String identificacion,
    required String telefono,
    required String correo,
    required String unidad,
    required String periodo,
    required List<NombramientoModel> nombramientos,
    required List<TrabajoExternoModel> trabajosExternos,
  }) async {
    final usuario = auth.currentUser;

    if (usuario == null) {
      throw Exception('No hay un usuario con sesión iniciada');
    }
    
    // Consulta el perfil del funcionario.
    final perfil = await firestore
        .collection('users')
        .doc(usuario.uid)
        .get();

    if (!perfil.exists) {
      throw Exception(
        'No se encontró el perfil del funcionario.',
      );
    }

    // Obtiene el superior asignado.
    final superiorId =
        (perfil.data()?['superiorId'] as String?)?.trim();

    if (superiorId == null || superiorId.isEmpty) {
      throw Exception(
        'El funcionario no tiene un superior asignado.',
      );
    }

    // Comprueba que el superior exista y tenga el rol correcto.
    final superior = await firestore
        .collection('users')
        .doc(superiorId)
        .get();

    if (!superior.exists ||
        superior.data()?['rol'] != 'superior') {
      throw Exception(
        'El superior asignado no es válido.',
      );
    }


    final referencia = firestore.collection('declarations').doc();

    final declaracion = DeclaracionModel(
      id: referencia.id,
      usuarioId: usuario.uid,
      nombreFuncionario: nombre,
      identificacion: identificacion,
      telefono: telefono,
      correo: correo,
      unidad: unidad,
      periodo: periodo,
      estado: 'BORRADOR',
      fechaCreacion: DateTime.now(),
    );

    final batch = firestore.batch();

    // Guarda los datos principales.

batch.set(referencia, {
  ...declaracion.toMap(),
  'id': referencia.id,
  'versionActual': 1,
  'superiorId': superiorId,
});


    // Crea la versión 1.
    final versionReferencia =
        referencia.collection('versions').doc('1');

    batch.set(versionReferencia, {
      'numero': 1,
      'estado': 'BORRADOR',
      'usuarioId': usuario.uid,
      'nombreFuncionario': nombre,
      'identificacion': identificacion,
      'telefono': telefono,
      'correo': correo,
      'unidad': unidad,
      'periodo': periodo,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'firmada': false,
    });

    // Guarda nombramientos en ambas estructuras.
    for (final nombramiento in nombramientos) {
      final id = referencia.collection('appointments').doc().id;
      final datos = nombramiento.toMap();

      batch.set(
        referencia.collection('appointments').doc(id),
        datos,
      );

      batch.set(
        versionReferencia.collection('appointments').doc(id),
        datos,
      );
    }

    // Guarda trabajos externos en ambas estructuras.
    for (final trabajo in trabajosExternos) {
      final id = referencia.collection('externalJobs').doc().id;
      final datos = trabajo.toMap();

      batch.set(
        referencia.collection('externalJobs').doc(id),
        datos,
      );

      batch.set(
        versionReferencia.collection('externalJobs').doc(id),
        datos,
      );
    }

    // Registra la creación en el historial.
    final eventoReferencia =
        referencia.collection('events').doc();

    batch.set(
      eventoReferencia,
      crearEvento(
        accion: 'DECLARACION_CREADA',
        usuarioId: usuario.uid,
        version: 1,
        estadoAnterior: 'NINGUNO',
        estadoNuevo: 'BORRADOR',
        observacion: 'Declaración creada por el funcionario.',
      ),
    );

    // Guarda todos los documentos en una sola operación.
    await batch.commit();

    return referencia.id;
  }

  // Revisa todos los horarios de una declaración.
  Future<List<String>> revisarHorarios(
    String declaracionId,
  ) async {
    final usuario = auth.currentUser;

    if (usuario == null) {
      throw Exception('Debés iniciar sesión');
    }

    final referencia =
        firestore.collection('declarations').doc(declaracionId);

    final declaracion = await referencia.get();

    if (!declaracion.exists) {
      throw Exception('La declaración no existe');
    }

    if (declaracion.data()?['usuarioId'] != usuario.uid) {
      throw Exception(
        'No tenés permiso para validar esta declaración',
      );
    }

    final nombramientos =
        await referencia.collection('appointments').get();

    final trabajos =
        await referencia.collection('externalJobs').get();

    final errores = <String>[];
    final horarios = <Map<String, dynamic>>[];
    final validador = ValidacionHorariosService();

    if (nombramientos.docs.isEmpty) {
      errores.add(
        'Debés registrar al menos un nombramiento.',
      );
    }

    // Revisa los nombramientos.
    for (int i = 0; i < nombramientos.docs.length; i++) {
      final datos = nombramientos.docs[i].data();
      final lista = datos['horarios'];

      if (lista is! List || lista.isEmpty) {
        errores.add(
          'El nombramiento ${i + 1} no tiene horarios.',
        );
        continue;
      }

      for (final horario in lista) {
        if (horario is Map) {
          horarios.add(
            Map<String, dynamic>.from(horario),
          );
        } else {
          errores.add(
            'El nombramiento ${i + 1} tiene un horario incorrecto.',
          );
        }
      }
    }

    // Revisa los trabajos externos.
    for (int i = 0; i < trabajos.docs.length; i++) {
      final datos = trabajos.docs[i].data();
      final lista = datos['horarios'];

      if (lista is! List || lista.isEmpty) {
        errores.add(
          'El trabajo externo ${i + 1} no tiene horarios.',
        );
        continue;
      }

      for (final horario in lista) {
        if (horario is Map) {
          horarios.add(
            Map<String, dynamic>.from(horario),
          );
        } else {
          errores.add(
            'El trabajo externo ${i + 1} tiene un horario incorrecto.',
          );
        }
      }
    }

    errores.addAll(
      validador.validarDeclaracionCompleta(horarios),
    );

    return errores;
  }

  // Valida una declaración y registra el cambio.
  Future<void> validarDeclaracion(
    String declaracionId,
  ) async {
    final usuario = auth.currentUser;

    if (usuario == null) {
      throw Exception('Debés iniciar sesión');
    }

    final referencia =
        firestore.collection('declarations').doc(declaracionId);

    final errores = await revisarHorarios(declaracionId);

    if (errores.isNotEmpty) {
      throw Exception(
        'Se encontraron errores:\n${errores.join('\n')}',
      );
    }

    await firestore.runTransaction((transaction) async {
      final documento = await transaction.get(referencia);

      if (!documento.exists) {
        throw Exception('La declaración no existe');
      }

      final datos = documento.data()!;

      if (datos['usuarioId'] != usuario.uid) {
        throw Exception(
          'No podés validar esta declaración',
        );
      }

      if (datos['estado'] != 'BORRADOR') {
        throw Exception(
          'La declaración no está en borrador',
        );
      }

      final version = (datos['versionActual'] as num?)
              ?.toInt() ??
          1;

      // Prepara el documento del historial.
      final eventoReferencia =
          referencia.collection('events').doc();

      // Cambia el estado de la declaración.
      transaction.update(referencia, {
        'estado': 'VALIDADA',
        'fechaValidacion': FieldValue.serverTimestamp(),
      });

      // Guarda el evento en la misma transacción.
      transaction.set(
        eventoReferencia,
        crearEvento(
          accion: 'DECLARACION_VALIDADA',
          usuarioId: usuario.uid,
          version: version,
          estadoAnterior: 'BORRADOR',
          estadoNuevo: 'VALIDADA',
          observacion: 'Horarios validados correctamente.',
        ),
      );
    });
  }

  // La firma permanece deshabilitada hasta implementar
  // protección de versiones y reglas de seguridad.
  Future<void> firmarDeclaracion(
    String declaracionId,
  ) async {
    throw UnimplementedError(
      'La firma estará disponible cuando se implemente '
      'el versionamiento seguro de las declaraciones.',
    );
  }
}
