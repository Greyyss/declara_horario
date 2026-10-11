
import 'package:flutter/material.dart';
import '../models/trabajo_externo_model.dart';

class TrabajoExternoForm extends StatefulWidget {
  final Function(TrabajoExternoModel) onAgregar;

  const TrabajoExternoForm({
    super.key,
    required this.onAgregar,
  });

  @override
  State<TrabajoExternoForm> createState() => _TrabajoExternoFormState();
}

class _TrabajoExternoFormState extends State<TrabajoExternoForm> {
  final _formKey = GlobalKey<FormState>();

  final institucionController = TextEditingController();
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

  String mostrarFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha';
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void agregarTrabajo() {
    if (!_formKey.currentState!.validate()) return;

    if (fechaInicio == null || fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione las fechas del trabajo'),
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

    final trabajo = TrabajoExternoModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      institucion: institucionController.text.trim(),
      cargo: cargoController.text.trim(),
      jornada: double.parse(
        jornadaController.text.trim().replaceAll(',', '.'),
      ),
      fechaInicio: fechaInicio!,
      fechaFin: fechaFin!,
      horarios: [],
    );

    widget.onAgregar(trabajo);

    institucionController.clear();
    cargoController.clear();
    jornadaController.clear();

    setState(() {
      fechaInicio = null;
      fechaFin = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trabajo externo agregado correctamente'),
      ),
    );
  }

  @override
  void dispose() {
    institucionController.dispose();
    cargoController.dispose();
    jornadaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agregar trabajo en otra institución',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          TextFormField(
            controller: institucionController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la institución',
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) {
                return 'Ingrese la institución';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: cargoController,
            decoration: const InputDecoration(
              labelText: 'Cargo o puesto',
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
              labelText: 'Jornada (ejemplo: 0.5)',
              border: OutlineInputBorder(),
            ),
            validator: (valor) {
              final numero = double.tryParse(
                (valor ?? '').trim().replaceAll(',', '.'),
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
            label: Text('Inicio: ${mostrarFecha(fechaInicio)}'),
          ),

          const SizedBox(height: 10),

          OutlinedButton.icon(
            onPressed: () => seleccionarFecha(false),
            icon: const Icon(Icons.calendar_month),
            label: Text('Fin: ${mostrarFecha(fechaFin)}'),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: agregarTrabajo,
            icon: const Icon(Icons.add),
            label: const Text('Agregar trabajo externo'),
          ),
        ],
      ),
    );
  }
}
