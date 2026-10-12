import 'package:material_ui/material_ui.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/glass.dart';

class ErrandCard extends StatelessWidget {
  const new({required this.task, super.key, this.onTap});

  final RunnerTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final runner = task.runner?.fullName;
    return Glass(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  taskTypeLabel(l10n, task.taskType),
                  style: TextStyle(
                    color: context.colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                taskStatusLabel(l10n, task.status),
                style: const TextStyle(
                  color: AppTheme.teal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: context.colors.ink,
            ),
          ),
          if (task.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.colors.muted),
            ),
          ],
          const SizedBox(height: 8),
          Text('${l10n.pickupAddress}: ${task.pickupAddress}'),
          const SizedBox(height: 2),
          Text('${l10n.dropoffAddress}: ${task.dropoffAddress}'),
          const SizedBox(height: 8),
          Text(
            'K ${task.estimatedCost}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (task.requester != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.postedBy} ${task.requester!.fullName}',
              style: TextStyle(color: context.colors.muted),
            ),
          ],
          Text(
            runner == null ? l10n.noRunnerYet : '${l10n.runner}: $runner',
            style: TextStyle(color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}
