
class ProgressService {
/// Oblicza procent ukończenia na podstawie
/// liczby ukończonych elementów i wszystkich elementów.
static double calculateProgress({
required int completed,
required int total,
}) {
if (total <= 0) {
return 0.0;
}

final double progress = completed / total;

return progress.clamp(0.0, 1.0);
}

/// Zamienia postęp 0.0–1.0 na procent 0–100.
static int percentage({
required int completed,
required int total,
}) {
return (calculateProgress(
completed: completed,
total: total,
) * 100).round();
}

/// Sprawdza, czy wszystko zostało ukończone.
static bool isCompleted({
required int completed,
required int total,
}) {
return total > 0 && completed >= total;
}

/// Zwraca tekst postępu, np. "65% ukończone".
static String progressText({
required int completed,
required int total,
}) {
final int percent = percentage(
completed: completed,
total: total,
);

return '$percent% ukończone';
}
}

