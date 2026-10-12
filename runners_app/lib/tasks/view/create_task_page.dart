import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/create_task_draft.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';
import 'package:runners_app/theme/glass.dart';

class CreateTaskPage extends StatefulWidget {
  const new({this.initialType, super.key});

  final String? initialType;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _dropoffAddress = TextEditingController();
  final _cost = TextEditingController();
  final _pickupLat = TextEditingController(text: '-15.4167');
  final _pickupLng = TextEditingController(text: '28.2833');
  final _dropoffLat = TextEditingController(text: '-15.4300');
  final _dropoffLng = TextEditingController(text: '28.3500');
  late String _taskType;
  var _step = 0;
  var _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _taskType = widget.initialType ?? 'store_pickup';
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _pickupAddress.dispose();
    _dropoffAddress.dispose();
    _cost.dispose();
    _pickupLat.dispose();
    _pickupLng.dispose();
    _dropoffLat.dispose();
    _dropoffLng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _step == 0
              ? () => Navigator.pop(context)
              : () => setState(() => _step -= 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _step == 2 ? l10n.stepThree : l10n.newErrand,
              style: const TextStyle(
                color: AppTheme.teal,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 2 ? l10n.reviewTitle : l10n.whatNeed,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(child: _stepBody(l10n)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFC2413B)),
                ),
              ),
            FilledButton(
              onPressed: _submitting ? null : _advance,
              child: Text(_step == 2 ? l10n.postErrand : l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepBody(AppLocalizations l10n) {
    if (_step == 0) {
      return ListView(
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(hintText: l10n.describeErrand),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(hintText: l10n.description),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final type in const [
                'store_pickup',
                'delivery',
                'home_chore',
              ])
                ChoiceChip(
                  label: Text(taskTypeLabel(l10n, type)),
                  selected: _taskType == type,
                  selectedColor: AppTheme.teal.withValues(alpha: 0.15),
                  onSelected: (_) => setState(() => _taskType = type),
                ),
            ],
          ),
        ],
      );
    }
    if (_step == 1) {
      return ListView(
        children: [
          FieldCaption(l10n.pickupAddress),
          TextField(controller: _pickupAddress),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _useMyLocation,
              child: Text(l10n.useMyLocation),
            ),
          ),
          FieldCaption(l10n.dropoffAddress),
          TextField(controller: _dropoffAddress),
          const SizedBox(height: 12),
          FieldCaption(l10n.estimatedCost),
          TextField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      );
    }
    return ListView(
      children: [
        Glass(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title.text,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: context.colors.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      taskTypeLabel(l10n, _taskType),
                      style: const TextStyle(
                        color: AppTheme.teal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _description.text,
                style: TextStyle(color: context.colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Place(
          label: l10n.pickupAddress,
          value: _pickupAddress.text,
          color: AppTheme.teal,
        ),
        const SizedBox(height: 8),
        _Place(
          label: l10n.dropoffAddress,
          value: _dropoffAddress.text,
          color: AppTheme.copper,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              l10n.estimatedCost,
              style: TextStyle(color: context.colors.muted),
            ),
            const Spacer(),
            Text(
              'K ${_cost.text}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Glass(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              l10n.paymentLater,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.muted),
            ),
          ),
        ),
      ],
    );
  }

  void _advance() {
    final l10n = context.l10n;
    if (_step == 0) {
      if (_title.text.trim().length < 3) {
        setState(() => _error = l10n.title);
        return;
      }
      if (_description.text.trim().isEmpty) {
        setState(() => _error = l10n.description);
        return;
      }
      setState(() {
        _step = 1;
        _error = null;
      });
      return;
    }
    if (_step == 1) {
      if (_pickupAddress.text.trim().length < 3) {
        setState(() => _error = l10n.pickupAddress);
        return;
      }
      if (_dropoffAddress.text.trim().length < 3) {
        setState(() => _error = l10n.dropoffAddress);
        return;
      }
      final cost = double.tryParse(_cost.text.trim());
      if (cost == null || cost < 0) {
        setState(() => _error = l10n.estimatedCost);
        return;
      }
      setState(() {
        _step = 2;
        _error = null;
      });
      return;
    }
    unawaited(_submit());
  }

  Future<void> _useMyLocation() async {
    try {
      final point = await const GeolocatorLocationSource().current();
      if (!mounted) return;
      setState(() {
        _pickupLat.text = point.lat.toString();
        _pickupLng.text = point.lng.toString();
        _error = null;
      });
    } on LocationFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  Future<void> _submit() async {
    final pickup = GeoPoint(
      lat: double.parse(_pickupLat.text.trim()),
      lng: double.parse(_pickupLng.text.trim()),
    );
    final dropoff = GeoPoint(
      lat: double.parse(_dropoffLat.text.trim()),
      lng: double.parse(_dropoffLng.text.trim()),
    );
    if (!pickup.isValid || !dropoff.isValid) {
      setState(() => _error = context.l10n.useMyLocation);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<TaskRepository>().create(
        CreateTaskDraft(
          title: _title.text,
          description: _description.text,
          taskType: _taskType,
          pickupAddress: _pickupAddress.text,
          dropoffAddress: _dropoffAddress.text,
          estimatedCost: _cost.text,
          pickup: pickup,
          dropoff: dropoff,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error.message;
      });
    }
  }
}

class _Place extends StatelessWidget {
  const new({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.5,
                    color: context.colors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: context.colors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
