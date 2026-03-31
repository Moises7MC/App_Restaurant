class Meal {
  final String id;
  final String name; // "Desayuno", "Almuerzo", "Cena"
  final String description;
  final String icon; // emoji o ruta de imagen

  const Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
