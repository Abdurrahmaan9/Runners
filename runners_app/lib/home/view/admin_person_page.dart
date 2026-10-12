import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runners_app/api/api_exception.dart';
import 'package:runners_app/l10n/l10n.dart';
import 'package:runners_app/models/app_user.dart';
import 'package:runners_app/tasks/data/task_repository.dart';
import 'package:runners_app/theme/app_theme.dart';
import 'package:runners_app/theme/errand_widgets.dart';
import 'package:runners_app/theme/glass.dart';

class AdminPersonPage extends StatefulWidget {
  const new({super.key, this.person, this.role});

  final AppUser? person;
  final String? role;

  @override
  State<AdminPersonPage> createState() => _AdminPersonPageState();
}

class _AdminPersonPageState extends State<AdminPersonPage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late String _role;
  AppUser? _person;
  var _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    _person = person;
    _name = TextEditingController(text: person?.fullName ?? '');
    _phone = TextEditingController(text: _localPhone(person?.phoneNumber));
    _password = TextEditingController();
    _role = widget.role ?? person?.role ?? 'requester';
    _phone.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phone.removeListener(_refresh);
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _ready {
    final passwordOk = _person != null || _password.text.length >= 8;
    return _name.text.trim().length >= 2 &&
        _phone.text.trim().isNotEmpty &&
        passwordOk &&
        !_saving;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final repository = context.read<TaskRepository>();
    try {
      final person = _person;
      final saved = person == null
          ? await repository.adminCreatePerson(
              phoneNumber: _phone.text,
              password: _password.text,
              fullName: _name.text.trim(),
              role: _role,
            )
          : await repository.adminUpdatePerson(
              id: person.id,
              phoneNumber: _phone.text,
              fullName: _name.text.trim(),
              role: _role,
              password: _password.text,
            );
      if (!mounted) return;
      if (widget.person == null) {
        Navigator.of(context).pop(saved);
        return;
      }
      setState(() {
        _person = saved;
        _password.clear();
        _saving = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _saving = false;
      });
    }
  }

  Future<void> _toggleBlocked() async {
    final person = _person;
    if (person == null) return;
    if (!person.blocked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = context.l10n;
          return AlertDialog(
            title: Text(l10n.blockUser),
            content: Text(l10n.blockUserBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelAction),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.blockUser),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await context.read<TaskRepository>().adminSetBlocked(
        id: person.id,
        blocked: !person.blocked,
      );
      if (!mounted) return;
      setState(() {
        _person = saved;
        _saving = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final person = _person;
    final creating = widget.person == null;

    return Scaffold(
      appBar: AppBar(title: Text(creating ? l10n.addUser : l10n.userDetails)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (person != null) ...[
            _Details(person: person),
            const SizedBox(height: 20),
          ],
          FieldCaption(l10n.fullName),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 16),
          FieldCaption(l10n.phoneNumber),
          PhoneNumberField(controller: _phone),
          const SizedBox(height: 16),
          FieldCaption(creating ? l10n.password : l10n.newPasswordOptional),
          TextField(
            controller: _password,
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FieldCaption(l10n.role),
          Row(
            children: [
              Expanded(
                child: _RoleChoice(
                  label: l10n.requester,
                  selected: _role == 'requester',
                  onTap: () => setState(() => _role = 'requester'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleChoice(
                  label: l10n.runner,
                  selected: _role == 'runner',
                  onTap: () => setState(() => _role = 'runner'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFC2413B))),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _ready ? () => unawaited(_save()) : null,
            child: Text(creating ? l10n.addUser : l10n.saveChanges),
          ),
          if (person != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC2413B),
                side: const BorderSide(color: Color(0xFFC2413B)),
              ),
              onPressed: _saving ? null : () => unawaited(_toggleBlocked()),
              child: Text(person.blocked ? l10n.unblockUser : l10n.blockUser),
            ),
          ],
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const new({required this.person});

  final AppUser person;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final joined = person.insertedAt?.split('T').first;
    final online = person.runnerProfile?.isOnline ?? false;

    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person.fullName,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            person.phoneNumber,
            style: TextStyle(color: context.colors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            person.isRunner ? l10n.runner : l10n.requester,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            person.isVerified ? l10n.verifiedLabel : l10n.notVerified,
            style: TextStyle(color: context.colors.muted),
          ),
          if (person.blocked) ...[
            const SizedBox(height: 4),
            Text(
              l10n.blockedLabel,
              style: const TextStyle(
                color: Color(0xFFC2413B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (online) ...[
            const SizedBox(height: 4),
            Text(
              l10n.activeNow,
              style: const TextStyle(
                color: AppTheme.copper,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (joined != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.joined} $joined',
              style: TextStyle(color: context.colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.teal : context.colors.field,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.white : context.colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

String _localPhone(String? phone) {
  if (phone == null) return '';
  if (phone.startsWith('+260')) return phone.substring(4);
  return phone;
}
