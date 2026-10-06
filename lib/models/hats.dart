/// Cosmetic hats, bought with the likes you collect.
class Hat {
  const Hat(this.id, this.name, this.price, this.index);

  final String id;
  final String name;
  final int price;

  /// Frame in assets/images/sprites/hats.png (24x18 each).
  final int index;

  static const width = 24.0;
  static const height = 18.0;
  static const sheet = 'sprites/hats.png';

  static Hat? byId(String? id) {
    for (final h in all) {
      if (h.id == id) return h;
    }
    return null;
  }

  static const all = [
    Hat('party', 'Cappello da festa', 30, 0),
    Hat('bow', 'Fiocco', 60, 4),
    Hat('cap', 'Berretto', 90, 3),
    Hat('flowers', 'Coroncina di fiori', 120, 9),
    Hat('beanie', 'Berretta col pompon', 140, 13),
    Hat('frog', 'Cappello rana', 180, 14),
    Hat('propeller', 'Elica', 160, 2),
    Hat('chef', 'Cappello da chef', 200, 6),
    Hat('cowboy', 'Cowboy', 260, 8),
    Hat('mushroom', 'Fungo', 280, 15),
    Hat('pirate', 'Pirata', 350, 12),
    Hat('witch', 'Strega', 320, 7),
    Hat('halo', 'Aureola', 400, 5),
    Hat('viking', 'Elmo vichingo', 450, 11),
    Hat('tophat', 'Cilindro', 600, 10),
    Hat('crown', 'Corona', 500, 1),
  ];
}
