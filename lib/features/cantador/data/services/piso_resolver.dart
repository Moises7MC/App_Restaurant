import '../../../../services/api_service.dart';

/// Helper que mapea cada número de mesa al piso al que pertenece.
///
/// Lo carga una vez al iniciar el cantador con el endpoint
/// `getTablesByFloor`. Después responde sin más llamadas.
///
/// Si una mesa no se encuentra (caso raro o "Para llevar" con tableNumber=0),
/// se considera del Piso 1 por defecto.
class PisoResolver {
  /// Lista de pisos detectados con sus nombres y los nº de mesa que contienen.
  /// Ej: [
  ///   { 'floorName': 'Piso 1', 'tableNumbers': {1, 2, 3, ...} },
  ///   { 'floorName': 'Piso 2', 'tableNumbers': {16, 17, ...} },
  /// ]
  List<FloorInfo> _floors = [];

  /// Si ya se cargaron los pisos
  bool get isLoaded => _floors.isNotEmpty;

  /// Lista pública de pisos (orden tal como vienen del backend)
  List<FloorInfo> get floors => List.unmodifiable(_floors);

  /// Carga los pisos desde el backend.
  /// Llamar al iniciar la pantalla del cantador.
  Future<void> load() async {
    try {
      final data = await ApiService.getTablesByFloor();
      _floors = data.map((floor) {
        final tables = floor['tables'] as List<dynamic>;
        final tableNumbers = tables
            .map<int>((t) => t['tableNumber'] as int)
            .toSet();
        return FloorInfo(
          floorName: floor['floorName'] as String,
          tableNumbers: tableNumbers,
        );
      }).toList();
    } catch (e) {
      // Fallback básico si el backend no responde:
      _floors = [
        FloorInfo(
          floorName: 'Piso 1',
          tableNumbers: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
        ),
        FloorInfo(
          floorName: 'Piso 2',
          tableNumbers: {
            16,
            17,
            18,
            19,
            20,
            21,
            22,
            23,
            24,
            25,
            26,
            27,
            28,
            29,
            30,
          },
        ),
      ];
    }
  }

  /// Devuelve el índice del piso al que pertenece la mesa (0, 1, ...).
  /// Si no se encuentra, devuelve 0 (primer piso).
  int getFloorIndex(int tableNumber) {
    for (int i = 0; i < _floors.length; i++) {
      if (_floors[i].tableNumbers.contains(tableNumber)) return i;
    }
    return 0;
  }

  /// Nombre del piso al que pertenece esta mesa
  String getFloorName(int tableNumber) {
    final idx = getFloorIndex(tableNumber);
    if (idx < _floors.length) return _floors[idx].floorName;
    return 'Piso ?';
  }
}

class FloorInfo {
  final String floorName;
  final Set<int> tableNumbers;

  FloorInfo({required this.floorName, required this.tableNumbers});
}
