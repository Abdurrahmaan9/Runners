import 'package:runners_app/l10n/l10n.dart';

String taskStatusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'posted' => l10n.statusPosted,
    'assigned' => l10n.statusAssigned,
    'runner_arrived' => l10n.statusRunnerArrived,
    'in_progress' => l10n.statusInProgress,
    'completed' => l10n.statusCompleted,
    'cancelled' => l10n.statusCancelled,
    _ => status,
  };
}

String taskTypeLabel(AppLocalizations l10n, String type) {
  return switch (type) {
    'store_pickup' => l10n.storePickup,
    'delivery' => l10n.delivery,
    'home_chore' => l10n.homeChore,
    _ => type,
  };
}
