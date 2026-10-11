
import 'package:flutter/material.dart';
import '../models/nombramiento_model.dart';

class NombramientoForm extends StatefulWidget {
  final Function(NombramientoModel) onAgregar;

  const NombramientoForm({
    super.key,
    required this.onAgregar,
  });

  @override
  State<NombramientoForm> createState() => _NombramientoFormState();
}

class _NombramientoFormState extends State<NombramientoForm> {
  final _formKey = GlobalKey<FormState>();

  final lugarController = TextEditingController();
  final cargoController = TextEditingController();
  final jornadaController = TextEditingController();

  DateTime? fechaInicio;
  DateTime? fechaFin;

  Future<void> seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha != null) {
      setState(() {
        if (esInicio) {
          fechaInicio = fecha;
        } else {
          fechaFin = fecha;
        }
      });
    }
  }

  void agregarNombramiento() {
    if (!_formKey.currentState!.validate()) return;

    if (fechaInicio == null || fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione las fechas del nombramiento'),
        ),
      );
      return;
    }

    if (fechaFin!.isBefore(fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha final no puede ser anterior a la inicial'),
        ),
      );
      return;
    }

    final nombramiento = NombramientoModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      lugarTrabajo: lugarController.text.trim(),
      cargo: cargoController.text.trim(),
      jornada: double.parse(jornadaController.text.trim().replaceAll(',', '.')),
      fechaInicio: fechaInicio!,
      fechaFin: fechaFin!,
      horarios: [],
    );

    widget.onAgregar(nombramiento);

    lugarController.clear();
    cargoController.clear();
    jornadaController.clear();

    setState(() {
      fechaInicio = null;
      fechaFin = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nombramiento agregado correctamente'),
      ),
    );
  }

  @override
  void dispose() {
    lugarController.dispose();
    cargoController.dispose();
    jornadaController.dispose();
    super.dispose();
  }

  String mostrarFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agregar nombramiento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          TextFormField(
            controller: lugarController,
            decoration: const InputDecoration(
              labelText: 'Lugar de trabajo',
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Ingrese el lugar de trabajo';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: cargoController,
            decoration: const InputDecoration(
              labelText: 'Cargo o categoría',
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Ingrese el cargo';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: jornadaController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Jornada (ejemplo: 1.0 o 0.5)',
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Ingrese la jornada';
              }

              final numero = double.tryParse(
                valor.trim().replaceAll(',', '.'),
              );

              if (numero == null || numero <= 0 || numero > 1) {
                return 'Ingrese una jornada entre 0 y 1';
              }

              return null;
            },
          ),

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: () => seleccionarFecha(true),
            icon: const Icon(Icons.calendar_month),
            label: Text(
              'Inicio: ${mostrarFecha(fechaInicio)}',
            ),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () => seleccionarFecha(false),
            icon: const Icon(Icons.calendar_month),
            label: Text(
              'Fin: ${mostrarFecha(fechaFin)}',
            ),
          ),

          const SizedBox(height: 15),

          ElevatedButton.icon(
            onPressed: agregarNombramiento,
            icon: const Icon(Icons.add),
            label: const Text('Agregar nombramiento'),
          ),
        ],
      ),
    );
  }
}
