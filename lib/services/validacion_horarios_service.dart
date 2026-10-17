
class ValidacionHorariosService {

  // Convierte una hora como "08:30" a minutos.
  int convertirAMinutos(String hora) {
    final partes = hora.split(':');

    if (partes.length != 2) {
      throw FormatException('Formato de hora incorrecto: $hora');
    }

    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);

    if (horas < 0 || horas > 23 ||
        minutos < 0 || minutos > 59) {
      throw FormatException('Hora incorrecta: $hora');
    }

    return horas * 60 + minutos;
  }

  // Revisa si dos intervalos se traslapan.
  bool hayTraslape(
    String inicio1,
    String fin1,
    String inicio2,
    String fin2,
  ) {
    final inicioA = convertirAMinutos(inicio1);
    final finA = convertirAMinutos(fin1);
    final inicioB = convertirAMinutos(inicio2);
    final finB = convertirAMinutos(fin2);

    return inicioA < finB && inicioB < finA;
  }

  // Compara dos horarios del mismo día.
  bool compararHorarios(
    Map<String, dynamic> horario1,
    Map<String, dynamic> horario2,
  ) {
    if (horario1['dia'] != horario2['dia']) {
      return false;
    }

    return hayTraslape(
      horario1['horaInicio'],
      horario1['horaFin'],
      horario2['horaInicio'],
      horario2['horaFin'],
    );
  }

  // Valida horarios dentro de un nombramiento.
  bool validarHorariosNombramiento(
    List<Map<String, dynamic>> horarios,
  ) {
    for (int i = 0; i < horarios.length; i++) {
      for (int j = i + 1; j < horarios.length; j++) {
        if (compararHorarios(horarios[i], horarios[j])) {
          return false;
        }
      }
    }

    return true;
  }

  // Valida horarios entre nombramientos.
  bool validarEntreNombramientos(
    List<Map<String, dynamic>> horarios1,
    List<Map<String, dynamic>> horarios2,
  ) {
    for (final horario1 in horarios1) {
      for (final horario2 in horarios2) {
        if (compararHorarios(horario1, horario2)) {
          return false;
        }
      }
    }

    return true;
  }

  // Valida horarios contra trabajos externos.
  bool validarTrabajoExterno(
    List<Map<String, dynamic>> horariosNombramiento,
    List<Map<String, dynamic>> horariosTrabajoExterno,
  ) {
    for (final horarioNombramiento in horariosNombramiento) {
      for (final horarioExterno in horariosTrabajoExterno) {
        if (compararHorarios(
          horarioNombramiento,
          horarioExterno,
        )) {
          return false;
        }
      }
    }

    return true;
  }

  // Comprueba que la jornada esté entre 0 y 1.
  bool validarJornada(double jornada) {
    return jornada > 0 && jornada <= 1.0;
  }

  // Suma las jornadas.
  double calcularJornadaTotal(List<double> jornadas) {
    double total = 0;

    for (final jornada in jornadas) {
      total += jornada;
    }

    return total;
  }

  // Revisa todos los horarios de una declaración.
  // Devuelve una lista de errores encontrados.
  List<String> validarDeclaracionCompleta(
    List<Map<String, dynamic>> horarios,
  ) {
    final errores = <String>[];
    final minutosPorDia = <String, int>{};

    for (int i = 0; i < horarios.length; i++) {
      final horario = horarios[i];

      try {
        final dia = horario['dia']?.toString() ?? '';
        final inicio = convertirAMinutos(
          horario['horaInicio'].toString(),
        );
        final fin = convertirAMinutos(
          horario['horaFin'].toString(),
        );

        if (dia.isEmpty) {
          errores.add(
            'El horario ${i + 1} no tiene día.',
          );
          continue;
        }

        if (inicio >= fin) {
          errores.add(
            'El horario ${i + 1} tiene una hora '
            'de finalización incorrecta.',
          );
          continue;
        }

        // No se permite incluir el período de almuerzo.
        if (inicio < 13 * 60 && fin > 12 * 60) {
          errores.add(
            'El horario ${i + 1} incluye el período '
            'de 12:00 m. a 1:00 p. m.',
          );
        }

        minutosPorDia[dia] =
            (minutosPorDia[dia] ?? 0) + (fin - inicio);

      } catch (error) {
        errores.add(
          'El horario ${i + 1} contiene datos incorrectos.',
        );
      }
    }

    // Revisa traslapes entre todos los horarios.
    for (int i = 0; i < horarios.length; i++) {
      for (int j = i + 1; j < horarios.length; j++) {
        try {
          if (compararHorarios(horarios[i], horarios[j])) {
            errores.add(
              'Los horarios ${i + 1} y ${j + 1} '
              'se traslapan.',
            );
          }
        } catch (_) {
          // El error de formato ya se informa arriba.
        }
      }
    }

    // Comprueba el máximo de 10 horas por día.
    minutosPorDia.forEach((dia, minutos) {
      if (minutos > 600) {
        errores.add(
          'El día $dia supera el máximo de '
          '10 horas declaradas.',
        );
      }
    });

    return errores;
  }
}
