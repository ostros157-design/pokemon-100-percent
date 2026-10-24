
class Game {
final String id;
final String name;
final String generation;
final String platform;
final String description;
final bool completed;

const Game({
required this.id,
required this.name,
required this.generation,
required this.platform,
required this.description,
this.completed = false,
});
}

