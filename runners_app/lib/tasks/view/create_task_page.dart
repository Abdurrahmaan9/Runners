import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/create_task_draft.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/view/task_labels.dart';

class CreateTaskPage extends StatefulWidget {
  const new({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _dropoffAddress = TextEditingController();
  final _cost = TextEditingController();
  final _pickupLat = TextEditingController(text: '-15.4167');
  final _pickupLng = TextEditingController(text: '28.2833');
  final _dropoffLat = TextEditingController(text: '-15.4300');
  final _dropoffLng = TextEditingController(text: '28.3500');
  var _taskType = 'delivery';
  var _submitting = false;
  String? _error;

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
      appBar: AppBar(title: Text(l10n.newErrand)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l10n.title),
              validator: (value) => (value == null || value.trim().length < 3)
                  ? l10n.title
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(labelText: l10n.description),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? l10n.description
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _taskType,
              decoration: InputDecoration(labelText: l10n.taskType),
              items: [
                for (final type in const [
                  'store_pickup',
                  'delivery',
                  'home_chore',
                ])
                  DropdownMenuItem(
                    value: type,
                    child: Text(taskTypeLabel(l10n, type)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _taskType = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pickupAddress,
              decoration: InputDecoration(labelText: l10n.pickupAddress),
              validator: (value) => (value == null || value.trim().length < 3)
                  ? l10n.pickupAddress
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _coordField(_pickupLat, l10n.pickupLat)),
                const SizedBox(width: 12),
                Expanded(child: _coordField(_pickupLng, l10n.pickupLng)),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _useMyLocation,
                child: Text(l10n.useMyLocation),
              ),
            ),
            TextFormField(
              controller: _dropoffAddress,
              decoration: InputDecoration(labelText: l10n.dropoffAddress),
              validator: (value) => (value == null || value.trim().length < 3)
                  ? l10n.dropoffAddress
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _coordField(_dropoffLat, l10n.dropoffLat)),
                const SizedBox(width: 12),
                Expanded(child: _coordField(_dropoffLng, l10n.dropoffLng)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: l10n.estimatedCost),
              validator: (value) {
                final cost = double.tryParse(value?.trim() ?? '');
                if (cost == null || cost < 0) return l10n.estimatedCost;
                return null;
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(l10n.postErrand),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final number = double.tryParse(value?.trim() ?? '');
        if (number == null) return label;
        return null;
      },
    );
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
    if (_formKey.currentState?.validate() != true) return;
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
