
class Achievement {
final String id;
final String title;
final String description;
final bool hidden;
final bool completed;

const Achievement({
required this.id,
required this.title,
required this.description,
this.hidden = false,
this.completed = false,
});
}

