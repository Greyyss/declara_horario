
class ValidacionHorariosService {

  // Convierte una hora como "08:30" a minutos.
  int convertirAMinutos(String hora) {
    final partes = hora.split(':');

    final horas = int.parse(partes[0]);
    final minutos = int.parse(partes[1]);

    return horas * 60 + minutos;
  }

  // Revisa si dos intervalos de tiempo se traslapan.
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

  // Compara dos horarios que tienen día, inicio y fin.
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
  
  // Revisa si hay horarios traslapados
  // dentro de un mismo nombramiento.
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

  // Revisa si dos nombramientos tienen horarios
  // que se cruzan en el mismo día.
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

  // Compara los horarios de un nombramiento
  // con los horarios de un trabajo externo.
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
  
  // Revisa que la jornada de un nombramiento
  // sea mayor que 0 y no supere 1.0.
  bool validarJornada(double jornada) {
    return jornada > 0 && jornada <= 1.0;
  }

  // Suma las jornadas de todos los nombramientos.
  double calcularJornadaTotal(List<double> jornadas) {
    double total = 0;

    for (final jornada in jornadas) {
      total += jornada;
    }

    return total;
  }

}
