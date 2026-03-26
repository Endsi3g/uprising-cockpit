import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/supabase_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _tradeOptions = ['plombier', 'couvreur'];
  String _selectedTrade = 'plombier';
  bool _notificationsEnabled = true;

  static const _defaultPresets = {
    'Fuite mineure': 800.0,
    'Fuite majeure': 2500.0,
    'Toiture complète': 12000.0,
    'Réparation toiture': 3500.0,
    'Gel/dégel': 1800.0,
    'Urgence générale': 1500.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Business profile
          _SectionTitle('Profil entreprise'),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.business_outlined,
                  label: 'Type de métier',
                  trailing: DropdownButton<String>(
                    value: _selectedTrade,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) =>
                        setState(() => _selectedTrade = v!),
                    items: _tradeOptions
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.capitalize()),
                            ))
                        .toList(),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _SettingRow(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications push',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _notificationsEnabled = v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionTitle('Valeurs estimées par défaut (\$ CAD)'),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: _defaultPresets.entries
                  .map((e) => Column(
                        children: [
                          _PresetRow(
                            label: e.key,
                            value: e.value,
                          ),
                          if (e.key != _defaultPresets.keys.last)
                            const Divider(
                                height: 1, color: AppColors.borderLight),
                        ],
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 24),
          _SectionTitle('Intégrations'),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.phone_outlined,
                  label: 'Twilio',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Configuré',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _SettingRow(
                  icon: Icons.smart_toy_outlined,
                  label: 'Groq AI',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Connecté',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _SettingRow(
                  icon: Icons.computer_outlined,
                  label: 'Ollama (local)',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Optionnel',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // App info
          Center(
            child: Text(
              'Uprising Cockpit v1.0.0\n© 2026 Uprising Purpose',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textTertiary),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5));
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _PresetRow extends StatefulWidget {
  final String label;
  final double value;
  const _PresetRow({required this.label, required this.value});

  @override
  State<_PresetRow> createState() => _PresetRowState();
}

class _PresetRowState extends State<_PresetRow> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
          GestureDetector(
            onTap: _editValue,
            child: Text(
              '${_value.toStringAsFixed(0)} \$',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _editValue() async {
    final ctrl = TextEditingController(text: _value.toStringAsFixed(0));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Valeur: ${widget.label}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '\$ CAD'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Sauvegarder')),
        ],
      ),
    );
    if (result != null) {
      final parsed = double.tryParse(result);
      if (parsed != null) setState(() => _value = parsed);
    }
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
