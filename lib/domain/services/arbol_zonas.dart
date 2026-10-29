import '../entities/zona.dart';

/// Ordena las zonas como las piensa la gente en Caracas:
/// Municipio → Parroquia → Urbanización (corrección de la revisión).
///
/// Lo usan el perfil de la trabajadora (elige varias), el perfil del cliente
/// y publicar/editar una solicitud (eligen una).
class ArbolZonas {
  ArbolZonas(Iterable<Zona> zonas) {
    for (final zona in zonas) {
      final municipio = _oSinDato(zona.municipio);
      final parroquia = _oSinDato(zona.parroquia);
      _arbol
          .putIfAbsent(municipio, () => {})
          .putIfAbsent(parroquia, () => [])
          .add(zona);
      _porId[zona.id] = zona;
    }
    for (final parroquias in _arbol.values) {
      for (final lista in parroquias.values) {
        lista.sort((a, b) => _comparar(a.nombre, b.nombre));
      }
    }
  }

  /// Grupo de las zonas que aún no tienen municipio o parroquia cargados.
  static const sinDato = 'Otras zonas';

  final _arbol = <String, Map<String, List<Zona>>>{};
  final _porId = <int, Zona>{};

  static String _oSinDato(String texto) =>
      texto.trim().isEmpty ? sinDato : texto.trim();

  /// Compara sin importar mayúsculas ni acentos, para que "Ávila" no quede
  /// al final de la lista.
  static int _comparar(String a, String b) =>
      _sinAcentos(a).compareTo(_sinAcentos(b));

  static String _sinAcentos(String texto) {
    const con = 'áéíóúüñÁÉÍÓÚÜÑ';
    const sin = 'aeiouunAEIOUUN';
    final buffer = StringBuffer();
    for (final letra in texto.split('')) {
      final i = con.indexOf(letra);
      buffer.write(i == -1 ? letra : sin[i]);
    }
    return buffer.toString().toLowerCase();
  }

  bool get estaVacio => _porId.isEmpty;

  /// Texto sin acentos ni mayúsculas, para comparar búsquedas.
  static String normalizar(String texto) => _sinAcentos(texto.trim());

  /// Barra de búsqueda: zonas cuya urbanización, parroquia o municipio
  /// contiene lo escrito, sin importar acentos ni mayúsculas ("boleita"
  /// encuentra "Boleíta"). Primero las urbanizaciones que empiezan así.
  List<Zona> filtrar(String consulta) {
    final buscado = normalizar(consulta);
    if (buscado.isEmpty) return const [];
    bool contiene(String texto) => _sinAcentos(texto).contains(buscado);
    final encontradas = [
      for (final zona in _porId.values)
        if (contiene(zona.nombre) ||
            contiene(zona.parroquia) ||
            contiene(zona.municipio))
          zona,
    ];
    int prioridad(Zona zona) {
      final nombre = _sinAcentos(zona.nombre);
      if (nombre.startsWith(buscado)) return 0;
      if (nombre.contains(buscado)) return 1;
      return 2;
    }

    encontradas.sort((a, b) {
      final porPrioridad = prioridad(a).compareTo(prioridad(b));
      return porPrioridad != 0 ? porPrioridad : _comparar(a.nombre, b.nombre);
    });
    return encontradas;
  }

  /// Municipios en orden alfabético ("Otras zonas" al final).
  List<String> get municipios => _ordenar(_arbol.keys);

  /// Parroquias de un municipio en orden alfabético.
  List<String> parroquias(String municipio) =>
      _ordenar(_arbol[municipio]?.keys ?? const []);

  /// Urbanizaciones de una parroquia, en orden alfabético.
  List<Zona> zonas(String municipio, String parroquia) =>
      List.unmodifiable(_arbol[municipio]?[parroquia] ?? const <Zona>[]);

  /// Todas las urbanizaciones de un municipio.
  List<Zona> zonasDelMunicipio(String municipio) => [
        for (final parroquia in parroquias(municipio))
          ...zonas(municipio, parroquia),
      ];

  Zona? buscar(int? id) => id == null ? null : _porId[id];

  /// Municipio y parroquia (como los muestra el árbol) de una zona.
  (String municipio, String parroquia)? ubicacion(int? id) {
    final zona = buscar(id);
    if (zona == null) return null;
    return (_oSinDato(zona.municipio), _oSinDato(zona.parroquia));
  }

  List<String> _ordenar(Iterable<String> textos) {
    final lista = textos.toList()
      ..sort((a, b) {
        if (a == sinDato) return 1;
        if (b == sinDato) return -1;
        return _comparar(a, b);
      });
    return lista;
  }
}
