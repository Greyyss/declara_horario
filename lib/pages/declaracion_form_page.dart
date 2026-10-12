import '../services/validacion_horarios_service.dart';
import '../services/declaracion_service.dart';
import 'horario_form.dart';
import 'package:flutter/material.dart';
import '../models/nombramiento_model.dart';
import 'nombramiento_form.dart';
import '../models/trabajo_externo_model.dart';
import 'trabajo_externo_form.dart';

class DeclaracionFormPage extends StatefulWidget {
  const DeclaracionFormPage({super.key});

  @override
  State<DeclaracionFormPage> createState() =>
      _DeclaracionFormPageState();
}

class _DeclaracionFormPageState extends State<DeclaracionFormPage> {
  final _formKey = GlobalKey<FormState>();

  final nombreController = TextEditingController();
  final identificacionController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();
  final unidadController = TextEditingController();
  final periodoController = TextEditingController();
  final DeclaracionService declaracionService = DeclaracionService();
  final ValidacionHorariosService validacionService =
    ValidacionHorariosService();

  bool guardando = false;
  // Lista de nombramientos agregados
  List<NombramientoModel> nombramientos = [];
  List<TrabajoExternoModel> trabajosExternos = [];

  void agregarNombramiento(NombramientoModel nombramiento) {
    setState(() {
      nombramientos.add(nombramiento);
    });
  }

  void eliminarNombramiento(int indice) {
    setState(() {
      nombramientos.removeAt(indice);
    });
  }

  
void agregarHorario(
  int indice,
  Map<String, dynamic> horario,
) {
  setState(() {
    nombramientos[indice].horarios.add(horario);
  });
}

void eliminarHorario(int indiceNombramiento, int indiceHorario) {
  setState(() {
    nombramientos[indiceNombramiento]
        .horarios
        .removeAt(indiceHorario);
  });
}

void agregarTrabajoExterno(TrabajoExternoModel trabajo) {
  setState(() {
    trabajosExternos.add(trabajo);
  });
}

void eliminarTrabajoExterno(int indice) {
  setState(() {
    trabajosExternos.removeAt(indice);
  });
}

void agregarHorarioExterno(
  int indice,
  Map<String, dynamic> horario,
) {
  setState(() {
    trabajosExternos[indice].horarios.add(horario);
  });
}

void eliminarHorarioExterno(
  int indiceTrabajo,
  int indiceHorario,
) {
  setState(() {
    trabajosExternos[indiceTrabajo]
        .horarios
        .removeAt(indiceHorario);
  });
}


  Widget crearCampo(
    String etiqueta,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          if (valor == null || valor.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }


Future<void> continuar() async {
  if (guardando) return;

  if (!_formKey.currentState!.validate()) return;

  if (nombramientos.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debe agregar al menos un nombramiento'),
      ),
    );
    return;
  }

  for (final nombramiento in nombramientos) {
    if (nombramiento.horarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Agregue horarios al nombramiento: '
            '${nombramiento.lugarTrabajo}',
          ),
        ),
      );
      return;
    }
  }

  for (final trabajo in trabajosExternos) {
    if (trabajo.horarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Agregue horarios al trabajo externo: '
            '${trabajo.institucion}',
          ),
        ),
      );
      return;
    }
  }
  
  // Validar traslapes dentro de cada nombramiento
  for (final nombramiento in nombramientos) {
    final horariosValidos =
        validacionService.validarHorariosNombramiento(
      nombramiento.horarios,
    );

    if (!horariosValidos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hay horarios traslapados en el nombramiento: '
            '${nombramiento.lugarTrabajo}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  // Validar traslapes entre diferentes nombramientos
  for (int i = 0; i < nombramientos.length; i++) {
    for (int j = i + 1; j < nombramientos.length; j++) {
      final primero = nombramientos[i];
      final segundo = nombramientos[j];

      // Comprobar si los períodos de trabajo coinciden
      final fechasCoinciden =
          !primero.fechaFin.isBefore(segundo.fechaInicio) &&
          !segundo.fechaFin.isBefore(primero.fechaInicio);

      if (fechasCoinciden) {
        final horariosValidos =
            validacionService.validarEntreNombramientos(
          primero.horarios,
          segundo.horarios,
        );

        if (!horariosValidos) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hay horarios traslapados entre los nombramientos '
                '${primero.lugarTrabajo} y ${segundo.lugarTrabajo}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }
  }

  // Validar conflictos entre nombramientos y trabajos externos
  for (final nombramiento in nombramientos) {
    for (final trabajo in trabajosExternos) {

      // Revisar si las fechas de trabajo coinciden
      final fechasCoinciden =
          !nombramiento.fechaFin.isBefore(trabajo.fechaInicio) &&
          !trabajo.fechaFin.isBefore(nombramiento.fechaInicio);

      if (fechasCoinciden) {
        final horariosValidos =
            validacionService.validarTrabajoExterno(
          nombramiento.horarios,
          trabajo.horarios,
        );

        if (!horariosValidos) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Hay horarios traslapados entre '
                '${nombramiento.lugarTrabajo} y '
                '${trabajo.institucion}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }
  }
  
  // Validar traslapes dentro de cada trabajo externo
  for (final trabajo in trabajosExternos) {
    final horariosValidos =
        validacionService.validarHorariosNombramiento(
      trabajo.horarios,
    );

    if (!horariosValidos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hay horarios traslapados en el trabajo externo: '
            '${trabajo.institucion}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  // Validar las jornadas de los nombramientos
  for (final nombramiento in nombramientos) {
    if (!validacionService.validarJornada(nombramiento.jornada)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La jornada del nombramiento '
            '${nombramiento.lugarTrabajo} debe ser '
            'mayor que 0 y menor o igual a 1.0',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  // Validar las jornadas de los trabajos externos
  for (final trabajo in trabajosExternos) {
    if (!validacionService.validarJornada(trabajo.jornada)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'La jornada del trabajo externo '
            '${trabajo.institucion} debe ser '
            'mayor que 0 y menor o igual a 1.0',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }

  // Calcular la jornada total de los nombramientos
  final jornadaTotal = validacionService.calcularJornadaTotal(
    nombramientos.map((n) => n.jornada).toList(),
  );

  debugPrint('Jornada total de nombramientos: $jornadaTotal');


  setState(() {
    guardando = true;
  });

  try {
    final id = await declaracionService.guardarDeclaracion(
      nombre: nombreController.text.trim(),
      identificacion: identificacionController.text.trim(),
      telefono: telefonoController.text.trim(),
      correo: correoController.text.trim(),
      unidad: unidadController.text.trim(),
      periodo: periodoController.text.trim(),
      nombramientos: nombramientos,
      trabajosExternos: trabajosExternos,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Declaración guardada correctamente'),
        backgroundColor: Colors.green,
      ),
    );

    debugPrint('Declaración guardada con ID: $id');

    Navigator.pop(context);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al guardar la declaración: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        guardando = false;
      });
    }
  }
}


  @override
  void dispose() {
    nombreController.dispose();
    identificacionController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    unidadController.dispose();
    periodoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva declaración de horario'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del funcionario',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  crearCampo('Nombre completo', nombreController),
                  crearCampo('Identificación', identificacionController),
                  crearCampo('Teléfono', telefonoController),
                  crearCampo('Correo electrónico', correoController),
                  crearCampo(
                    'Unidad académica o administrativa',
                    unidadController,
                  ),
                  crearCampo('Período', periodoController),

                  const Divider(height: 40),

                  // Formulario para agregar nombramientos
                  NombramientoForm(
                    onAgregar: agregarNombramiento,
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'Nombramientos registrados',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (nombramientos.isEmpty)
                    const Text(
                      'Todavía no se han agregado nombramientos.',
                    ),

                  // Mostrar todos los nombramientos
                  ...nombramientos.asMap().entries.map((entrada) {
                    final indice = entrada.key;
                    final nombramiento = entrada.value;

                    
return Card(
  margin: const EdgeInsets.only(bottom: 15),
  child: Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                nombramiento.lugarTrabajo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                eliminarNombramiento(indice);
              },
            ),
          ],
        ),

        Text('Cargo: ${nombramiento.cargo}'),
        Text('Jornada: ${nombramiento.jornada}'),

        Text(
          'Inicio: ${nombramiento.fechaInicio.day}/'
          '${nombramiento.fechaInicio.month}/'
          '${nombramiento.fechaInicio.year}',
        ),

        Text(
          'Fin: ${nombramiento.fechaFin.day}/'
          '${nombramiento.fechaFin.month}/'
          '${nombramiento.fechaFin.year}',
        ),

        const Divider(height: 30),

        const Text(
          'Horarios registrados',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        if (nombramiento.horarios.isEmpty)
          const Text('No hay horarios agregados.'),

        ...nombramiento.horarios.asMap().entries.map((entradaHorario) {
          final indiceHorario = entradaHorario.key;
          final horario = entradaHorario.value;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${horario['dia']}'),
            subtitle: Text(
              '${horario['horaInicio']} - ${horario['horaFin']}',
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              ),
              onPressed: () {
                eliminarHorario(indice, indiceHorario);
              },
            ),
          );
        }),

        const Divider(height: 30),

        HorarioForm(
          key: ValueKey(nombramiento.id),
          onAgregar: (horario) {
            agregarHorario(indice, horario);
          },
        ),
      ],
    ),
  ),
);

                  }),

const Divider(height: 40),

const Text(
  'Trabajos en otras instituciones',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

const Text(
  'Si trabaja en otra institución, registre aquí '
  'los datos y horarios correspondientes.',
),

const SizedBox(height: 20),

TrabajoExternoForm(
  onAgregar: agregarTrabajoExterno,
),

const SizedBox(height: 25),

const Text(
  'Trabajos externos registrados',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

if (trabajosExternos.isEmpty)
  const Text('No se han registrado trabajos externos.'),

...trabajosExternos.asMap().entries.map((entrada) {
  final indice = entrada.key;
  final trabajo = entrada.value;

  return Card(
    margin: const EdgeInsets.only(bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trabajo.institucion,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  eliminarTrabajoExterno(indice);
                },
              ),
            ],
          ),

          Text('Cargo: ${trabajo.cargo}'),
          Text('Jornada: ${trabajo.jornada}'),

          Text(
            'Inicio: ${trabajo.fechaInicio.day}/'
            '${trabajo.fechaInicio.month}/'
            '${trabajo.fechaInicio.year}',
          ),

          Text(
            'Fin: ${trabajo.fechaFin.day}/'
            '${trabajo.fechaFin.month}/'
            '${trabajo.fechaFin.year}',
          ),

          const Divider(height: 30),

          const Text(
            'Horarios registrados',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          if (trabajo.horarios.isEmpty)
            const Text('No hay horarios agregados.'),

          ...trabajo.horarios.asMap().entries.map((entradaHorario) {
            final indiceHorario = entradaHorario.key;
            final horario = entradaHorario.value;

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${horario['dia']}'),
              subtitle: Text(
                '${horario['horaInicio']} - ${horario['horaFin']}',
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
                onPressed: () {
                  eliminarHorarioExterno(
                    indice,
                    indiceHorario,
                  );
                },
              ),
            );
          }),

          const Divider(height: 30),

          HorarioForm(
            key: ValueKey('externo_${trabajo.id}'),
            onAgregar: (horario) {
              agregarHorarioExterno(indice, horario);
            },
          ),
        ],
      ),
    ),
  );
}),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                   child: ElevatedButton(
  onPressed: guardando ? null : continuar,
  child: guardando
      ? const CircularProgressIndicator()
      : const Text('Guardar declaración'),
),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

