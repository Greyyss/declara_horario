
import 'package:flutter/material.dart';

class HorarioForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onAgregar;

  const HorarioForm({
    super.key,
    required this.onAgregar,
  });

  @override
  State<HorarioForm> createState() => _HorarioFormState();
}

class _HorarioFormState extends State<HorarioForm> {
  String diaSeleccionado = 'Lunes';
  TimeOfDay? horaInicio;
  TimeOfDay? horaFin;

  final List<String> dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  Future<void> seleccionarHora(bool esInicio) async {
    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (hora != null) {
      setState(() {
        if (esInicio) {
          horaInicio = hora;
        } else {
          horaFin = hora;
        }
      });
    }
  }

  String convertirHora(TimeOfDay hora) {
    final horas = hora.hour.toString().padLeft(2, '0');
    final minutos = hora.minute.toString().padLeft(2, '0');
    return '$horas:$minutos';
  }

  void agregarHorario() {
    if (horaInicio == null || horaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione ambas horas'),
        ),
      );
      return;
    }

    final inicio = horaInicio!.hour * 60 + horaInicio!.minute;
    final fin = horaFin!.hour * 60 + horaFin!.minute;

    if (fin <= inicio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora final debe ser posterior a la inicial'),
        ),
      );
      return;
    }

    final horario = {
      'dia': diaSeleccionado,
      'horaInicio': convertirHora(horaInicio!),
      'horaFin': convertirHora(horaFin!),
    };

    widget.onAgregar(horario);

    setState(() {
      horaInicio = null;
      horaFin = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Horario agregado correctamente'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agregar horario',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        DropdownButtonFormField<String>(
          value: diaSeleccionado,
          decoration: const InputDecoration(
            labelText: 'Día de la semana',
            border: OutlineInputBorder(),
          ),
          items: dias.map((dia) {
            return DropdownMenuItem(
              value: dia,
              child: Text(dia),
            );
          }).toList(),
          onChanged: (valor) {
            if (valor != null) {
              setState(() {
                diaSeleccionado = valor;
              });
            }
          },
        ),

        const SizedBox(height: 15),

        OutlinedButton.icon(
          onPressed: () => seleccionarHora(true),
          icon: const Icon(Icons.access_time),
          label: Text(
            horaInicio == null
                ? 'Seleccionar hora de inicio'
                : 'Inicio: ${horaInicio!.format(context)}',
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: () => seleccionarHora(false),
          icon: const Icon(Icons.access_time),
          label: Text(
            horaFin == null
                ? 'Seleccionar hora de fin'
                : 'Fin: ${horaFin!.format(context)}',
          ),
        ),

        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: agregarHorario,
          icon: const Icon(Icons.add),
          label: const Text('Agregar horario'),
        ),
      ],
    );
  }
}
