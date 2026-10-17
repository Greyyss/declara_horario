
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/declaracion_service.dart';

class DetalleDeclaracionPage extends StatelessWidget {
  final String declaracionId;

  const DetalleDeclaracionPage({
    super.key,
    required this.declaracionId,
  });

  // Convierte las fechas de Firebase a un formato legible.
  String mostrarFecha(dynamic fecha) {
    if (fecha is Timestamp) {
      final valor = fecha.toDate();
      return '${valor.day}/${valor.month}/${valor.year}';
    }

    return 'Sin fecha';
  }

  // Muestra el nombre y valor de un campo.
  Widget mostrarDato(String titulo, dynamic valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6747A5),
            ),
          ),
          const SizedBox(height: 3),
          Text(valor?.toString() ?? 'Sin información'),
        ],
      ),
    );
  }

  // Muestra los horarios registrados.
  Widget mostrarHorarios(dynamic horarios) {
    if (horarios is! List || horarios.isEmpty) {
      return const Text('No hay horarios registrados');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: horarios.map<Widget>((horario) {
        if (horario is! Map) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(
            '${horario['dia'] ?? 'Sin día'}: '
            '${horario['horaInicio'] ?? '--:--'} - '
            '${horario['horaFin'] ?? '--:--'}',
          ),
        );
      }).toList(),
    );
  }

  // Muestra nombramientos o trabajos externos.
  Widget mostrarSeccion(String titulo, String coleccion) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('declarations')
          .doc(declaracionId)
          .collection(coleccion)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error al cargar $titulo');
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final documentos = snapshot.data!.docs;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6747A5),
                  ),
                ),
                const SizedBox(height: 12),

                if (documentos.isEmpty)
                  const Text('No hay registros'),

                ...documentos.asMap().entries.map((entrada) {
                  final datos = entrada.value.data();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registro ${entrada.key + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        mostrarDato(
                          coleccion == 'appointments'
                              ? 'Lugar de trabajo'
                              : 'Institución',
                          coleccion == 'appointments'
                              ? datos['lugarTrabajo']
                              : datos['institucion'],
                        ),

                        mostrarDato('Cargo', datos['cargo']),
                        mostrarDato('Jornada', datos['jornada']),

                        mostrarDato(
                          'Fecha de inicio',
                          mostrarFecha(datos['fechaInicio']),
                        ),

                        mostrarDato(
                          'Fecha de finalización',
                          mostrarFecha(datos['fechaFin']),
                        ),

                        const Text(
                          'Horarios:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6747A5),
                          ),
                        ),

                        const SizedBox(height: 5),
                        mostrarHorarios(datos['horarios']),
                        const Divider(),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Muestra mensajes al usuario.
  void mostrarMensaje(
    BuildContext context,
    String mensaje, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // Valida el estado de la declaración.
  // Pendiente: integrar todas las reglas de horarios.
  Future<void> validarDeclaracion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Validar declaración'),
          content: const Text(
            'Se registrará una validación preliminar. '
            'Todavía falta integrar la comprobación completa '
            'de horarios y jornadas antes de habilitar la firma.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !context.mounted) return;

    try {
      await DeclaracionService().validarDeclaracion(declaracionId);

      if (!context.mounted) return;

      mostrarMensaje(
        context,
        'Estado actualizado a VALIDADA. '
        'Falta completar la validación de horarios.',
      );
    } catch (error) {
      if (!context.mounted) return;

      mostrarMensaje(
        context,
        'No se pudo validar: $error',
        error: true,
      );
    }
  }

  // Muestra la declaración bajo juramento.
  Future<bool> confirmarJuramento(BuildContext context) async {
    bool aceptado = false;

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualizar) {
            return AlertDialog(
              title: const Text(
                'Declaración bajo juramento',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gavel,
                      size: 48,
                      color: Color(0xFF6747A5),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Declaro bajo juramento que la información '
                      'registrada en esta declaración de horario '
                      'y jornada de trabajo es verdadera, completa '
                      'y corresponde a mis condiciones laborales.',
                    ),

                    const SizedBox(height: 18),

                    CheckboxListTile(
                      value: aceptado,
                      activeColor: const Color(0xFF6747A5),
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'He leído la declaración y confirmo '
                        'que la información es correcta.',
                      ),
                      onChanged: (valor) {
                        actualizar(() {
                          aceptado = valor ?? false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton.icon(
                  onPressed: aceptado
                      ? () => Navigator.pop(dialogContext, true)
                      : null,
                  icon: const Icon(Icons.draw),
                  label: const Text('Confirmar firma'),
                ),
              ],
            );
          },
        );
      },
    );

    return resultado == true;
  }

  // Registra la firma del declarante.
  Future<void> firmarDeclaracion(BuildContext context) async {
    final confirmado = await confirmarJuramento(context);

    if (!confirmado || !context.mounted) return;

    try {
      await DeclaracionService().firmarDeclaracion(declaracionId);

      if (!context.mounted) return;

      mostrarMensaje(
        context,
        'Firma registrada correctamente.',
      );
    } catch (error) {
      if (!context.mounted) return;

      mostrarMensaje(
        context,
        'No se pudo firmar: $error',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de declaración'),
        backgroundColor: const Color(0xFF6747A5),
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('declarations')
            .doc(declaracionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar la declaración'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text('La declaración no existe'),
            );
          }

          final datos = snapshot.data!.data()!;
          final estado = datos['estado'] ?? 'BORRADOR';
          final usuario = FirebaseAuth.instance.currentUser;

          final esPropietario = usuario != null &&
              datos['usuarioId'] == usuario.uid;

          final puedeValidar =
              esPropietario && estado == 'BORRADOR';

          // La firma se habilitará cuando completemos
          // la validación real y el versionamiento.
          const firmaHabilitada = false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información del funcionario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6747A5),
                        ),
                      ),

                      const SizedBox(height: 15),

                      mostrarDato(
                        'Nombre completo',
                        datos['nombreFuncionario'],
                      ),
                      mostrarDato(
                        'Identificación',
                        datos['identificacion'],
                      ),
                      mostrarDato('Teléfono', datos['telefono']),
                      mostrarDato('Correo', datos['correo']),
                      mostrarDato('Unidad', datos['unidad']),
                      mostrarDato('Período', datos['periodo']),
                      mostrarDato('Estado', estado),
                      mostrarDato(
                        'Versión actual',
                        datos['versionActual'] ?? 1,
                      ),
                      mostrarDato(
                        'Fecha de creación',
                        mostrarFecha(datos['fechaCreacion']),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              mostrarSeccion(
                'Nombramientos',
                'appointments',
              ),

              mostrarSeccion(
                'Trabajos externos',
                'externalJobs',
              ),

              if (puedeValidar) ...[
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => validarDeclaracion(context),
                    icon: const Icon(Icons.fact_check),
                    label: const Text('Validar declaración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6747A5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],

              if (esPropietario && estado == 'VALIDADA') ...[
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: firmaHabilitada
                        ? () => firmarDeclaracion(context)
                        : null,
                    icon: const Icon(Icons.draw),
                    label: const Text('Firmar declaración'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'La firma estará disponible después de '
                  'completar la validación de horarios y '
                  'el registro seguro de versiones.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],

              if (estado == 'FIRMADA_POR_DECLARANTE')
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'La firma del declarante está registrada. '
                      'Está pendiente completar el envío '
                      'al superior responsable.',
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
