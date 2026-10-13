import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/create_task_draft.dart';
import 'package:runners_app/models/geo_point.dart';
import 'package:runners_app/models/runner_task.dart';
import 'package:runners_app/models/zambia.dart';
import 'package:runners_app/runner/data/location_source.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/tasks/data/zambia_places.dart';
import 'package:runners_app/tasks/view/errand_map.dart';
import 'package:runners_app/tasks/view/task_labels.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';
import 'package:runners_app/theme/glass.dart';

class CreateTaskPage extends StatefulWidget {
  const new({this.initialType, this.task, super.key});

  final String? initialType;
  final RunnerTask? task;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _dropoffAddress = TextEditingController();
  final _cost = TextEditingController();
  final _search = TextEditingController();
  Timer? _searchTimer;
  List<PlaceHit> _results = const [];
  var _searching = false;
  late String _taskType;
  GeoPoint? _pickup;
  GeoPoint? _dropoff;
  GeoPoint? _camera;
  _Pin _placing = _Pin.pickup;
  var _step = 0;
  var _submitting = false;
  var _locating = false;
  String? _error;

  bool get _editing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _taskType = task?.taskType ?? widget.initialType ?? 'store_pickup';
    if (task == null) return;
    _title.text = task.title;
    _description.text = task.description;
    _pickupAddress.text = task.pickupAddress;
    _dropoffAddress.text = task.dropoffAddress;
    _cost.text = task.estimatedCost;
    _pickup = task.pickupLocation;
    _dropoff = task.dropoffLocation;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _pickupAddress.dispose();
    _dropoffAddress.dispose();
    _cost.dispose();
    _search.dispose();
    _searchTimer?.cancel();
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
              _editing
                  ? l10n.editErrand
                  : (_step == 2 ? l10n.stepThree : l10n.newErrand),
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
              child: Text(
                _step == 2
                    ? (_editing ? l10n.saveChanges : l10n.postErrand)
                    : l10n.continueAction,
              ),
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
    if (_step == 1) return _places(l10n);
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
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 180,
            child: ErrandMap(
              stops: _stops(l10n),
              routes: _route(),
              gestures: false,
            ),
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
      if (_pickup == null) {
        setState(() => _error = l10n.placePickup);
        return;
      }
      if (_dropoff == null) {
        setState(() => _error = l10n.placeDropoff);
        return;
      }
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

  Widget _places(AppLocalizations l10n) {
    final placingPickup = _placing == _Pin.pickup;
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: ErrandMap(
              stops: _stops(l10n),
              routes: _route(),
              follow: _camera,
              onTap: _point,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              TextField(
                controller: _search,
                onChanged: _queueSearch,
                decoration: InputDecoration(hintText: l10n.searchZambia),
              ),
              if (_searching)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(color: AppTheme.teal),
                ),
              if (!_searching &&
                  _search.text.trim().length >= 3 &&
                  _results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.searchEmpty,
                    style: TextStyle(color: context.colors.muted),
                  ),
                ),
              for (final hit in _results)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(hit.name, maxLines: 2),
                  onTap: () => _choose(hit),
                ),
              const SizedBox(height: 8),
              Text(
                placingPickup ? l10n.placePickup : l10n.placeDropoff,
                style: TextStyle(color: context.colors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.pickupPin),
                    selected: placingPickup,
                    selectedColor: AppTheme.teal.withValues(alpha: 0.18),
                    onSelected: (_) => setState(() => _placing = _Pin.pickup),
                  ),
                  ChoiceChip(
                    label: Text(l10n.dropoffPin),
                    selected: !placingPickup,
                    selectedColor: AppTheme.copper.withValues(alpha: 0.18),
                    onSelected: (_) => setState(() => _placing = _Pin.dropoff),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _locating ? null : _useMyLocation,
                  child: Text(l10n.useMyLocation),
                ),
              ),
              FieldCaption(l10n.pickupAddress),
              TextField(controller: _pickupAddress),
              const SizedBox(height: 12),
              FieldCaption(l10n.dropoffAddress),
              TextField(controller: _dropoffAddress),
              const SizedBox(height: 12),
              FieldCaption(l10n.estimatedCost),
              TextField(
                controller: _cost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<ErrandStop> _stops(AppLocalizations l10n) {
    final pickup = _pickup;
    final dropoff = _dropoff;
    return [
      if (pickup != null)
        ErrandStop(
          id: 'pickup',
          point: pickup,
          kind: ErrandStopKind.pickup,
          title: l10n.pickupAddress,
        ),
      if (dropoff != null)
        ErrandStop(
          id: 'dropoff',
          point: dropoff,
          kind: ErrandStopKind.dropoff,
          title: l10n.dropoffAddress,
        ),
    ];
  }

  List<List<GeoPoint>> _route() {
    final pickup = _pickup;
    final dropoff = _dropoff;
    if (pickup == null || dropoff == null) return const [];
    return [
      [pickup, dropoff],
    ];
  }

  void _queueSearch(String value) {
    _searchTimer?.cancel();
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _results = const [];
        _searching = false;
      });
      return;
    }
    _searchTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_runSearch(query)),
    );
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    try {
      final hits = await const ZambiaPlaces().search(query);
      if (!mounted || _search.text.trim() != query) return;
      setState(() {
        _results = hits;
        _searching = false;
      });
    } on Object {
      if (!mounted || _search.text.trim() != query) return;
      setState(() {
        _results = const [];
        _searching = false;
        _error = context.l10n.searchFailed;
      });
    }
  }

  void _choose(PlaceHit hit) {
    final field = _placing == _Pin.pickup ? _pickupAddress : _dropoffAddress;
    setState(() {
      _place(hit.point, moveCamera: true);
      field.text = hit.name;
      _results = const [];
      _search.clear();
      _searching = false;
      _error = null;
    });
  }

  void _point(GeoPoint point) {
    if (!inZambia(point)) {
      setState(() => _error = context.l10n.outsideZambia);
      return;
    }
    setState(() {
      _place(point, moveCamera: false);
      _error = null;
    });
  }

  void _place(GeoPoint point, {required bool moveCamera}) {
    if (_placing == _Pin.pickup) {
      _pickup = point;
      if (_dropoff == null) _placing = _Pin.dropoff;
    } else {
      _dropoff = point;
    }
    if (moveCamera) _camera = point;
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final point = await const GeolocatorLocationSource().current();
      if (!mounted) return;
      if (!inZambia(point)) {
        setState(() {
          _locating = false;
          _error = context.l10n.outsideZambia;
        });
        return;
      }
      setState(() {
        _place(point, moveCamera: true);
        _locating = false;
      });
    } on LocationFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _error = error.message;
      });
    }
  }

  Future<void> _submit() async {
    final pickup = _pickup;
    final dropoff = _dropoff;
    if (pickup == null ||
        dropoff == null ||
        !pickup.isValid ||
        !dropoff.isValid) {
      setState(() => _error = context.l10n.placePickup);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final draft = CreateTaskDraft(
        title: _title.text,
        description: _description.text,
        taskType: _taskType,
        pickupAddress: _pickupAddress.text,
        dropoffAddress: _dropoffAddress.text,
        estimatedCost: _cost.text,
        pickup: pickup,
        dropoff: dropoff,
      );
      final existing = widget.task;
      final repository = context.read<TaskRepository>();
      if (existing == null) {
        await repository.create(draft);
      } else {
        await repository.update(existing.id, draft);
      }
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

enum _Pin { pickup, dropoff }

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
