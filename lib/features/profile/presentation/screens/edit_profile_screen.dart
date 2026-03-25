import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';

const _primary = Color(0xFF1D9E75);

const _stages = [
  ('idea', 'Idea'),
  ('mvp', 'MVP'),
  ('early', 'Early stage'),
  ('growth', 'Growth'),
  ('scale', 'Scale'),
  ('executive', 'Ejecutivo'),
  ('investor', 'Inversor'),
];

const _goals = [
  ('cofounder', 'Cofundador'),
  ('clients', 'Clientes'),
  ('investors', 'Inversores'),
  ('talent', 'Talento'),
  ('mentors', 'Mentores'),
  ('network', 'Expandir red'),
  ('friends', 'Amigos'),
];

const _mbtis = [
  'INTJ', 'INTP', 'ENTJ', 'ENTP',
  'INFJ', 'INFP', 'ENFJ', 'ENFP',
  'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
  'ISTP', 'ISFP', 'ESTP', 'ESFP',
];

// Pares (valor_backend, etiqueta_display)
const _interestOptions = [
  ('ia', 'IA'),
  ('fintech', 'Fintech'),
  ('saas', 'SaaS'),
  ('e-commerce', 'E-commerce'),
  ('salud', 'Salud'),
  ('educación', 'Educación'),
  ('retail', 'Retail'),
  ('gastronomía', 'Gastronomía'),
  ('sostenibilidad', 'Sostenibilidad'),
  ('cripto', 'Cripto'),
  ('real estate', 'Real estate'),
  ('marketing', 'Marketing'),
  ('legal', 'Legal'),
  ('rrhh', 'RRHH'),
  ('b2b', 'B2B'),
  ('startups', 'Startups'),
  ('producto', 'Producto'),
  ('ventas', 'Ventas'),
  ('liderazgo', 'Liderazgo'),
];

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();

  String? _stage;
  String? _lookingFor;
  String? _mbti;
  final Set<String> _selectedInterests = {};
  List<(String, String)> _allInterestOptions = List.from(_interestOptions);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      _nameCtrl.text = profile.name ?? '';
      _bioCtrl.text = profile.bio ?? '';
      _industryCtrl.text = profile.industry ?? '';
      _linkedinCtrl.text = profile.linkedinUrl ?? '';
      _stage = profile.stage;
      _lookingFor = profile.lookingFor;
      _mbti = profile.mbti;

      // Pre-seleccionar intereses existentes
      for (final t in profile.interestTags) {
        _selectedInterests.add(t.tag);
      }

      // Agregar al listado los intereses del perfil que no estén en la lista predefinida
      final predefinedKeys = _interestOptions.map((o) => o.$1).toSet();
      final extras = profile.interestTags
          .where((t) => !predefinedKeys.contains(t.tag))
          .map((t) => (t.tag, _capitalize(t.tag)))
          .toList();
      if (extras.isNotEmpty) {
        _allInterestOptions = [..._interestOptions, ...extras];
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _industryCtrl.dispose();
    _linkedinCtrl.dispose();
    super.dispose();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final error = await ref.read(profileProvider.notifier).saveProfile(
          name: _nameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          industry: _industryCtrl.text.trim(),
          stage: _stage,
          lookingFor: _lookingFor,
          linkedinUrl: _linkedinCtrl.text.trim(),
          mbti: _mbti,
          interests: _selectedInterests.toList(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Perfil actualizado ✓'),
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar perfil'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _primary),
                      )
                    : const Text(
                        'Guardar',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: _primary),
                      ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // ── BÁSICO ────────────────────────────────────────────────────
              const _SectionLabel('Básico'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  alignLabelWithHint: true,
                  hintText: 'Cuéntale a la mesa quién eres…',
                ),
                maxLines: 3,
                maxLength: 200,
              ),

              // ── CARRERA ───────────────────────────────────────────────────
              const _SectionLabel('Carrera'),
              TextFormField(
                controller: _industryCtrl,
                decoration:
                    const InputDecoration(labelText: 'Industria / Sector'),
              ),
              const SizedBox(height: 12),
              _PickerField(
                label: 'Etapa',
                selected: _stage,
                options: _stages,
                onChanged: (v) => setState(() => _stage = v),
              ),

              // ── OBJETIVO ──────────────────────────────────────────────────
              const _SectionLabel('Objetivo en la mesa'),
              _PickerField(
                label: 'Busco',
                selected: _lookingFor,
                options: _goals,
                onChanged: (v) => setState(() => _lookingFor = v),
              ),

              // ── PERSONALIDAD ──────────────────────────────────────────────
              const _SectionLabel('Personalidad'),
              _MbtiGrid(
                selected: _mbti,
                onChanged: (v) => setState(() => _mbti = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkedinCtrl,
                decoration: const InputDecoration(
                  labelText: 'LinkedIn URL',
                  hintText: 'https://linkedin.com/in/...',
                  prefixIcon: Icon(Icons.link_rounded, size: 20),
                ),
                keyboardType: TextInputType.url,
              ),

              // ── INTERESES ─────────────────────────────────────────────────
              const _SectionLabel('Intereses'),
              Text(
                'Selecciona hasta 5 temas que te apasionen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allInterestOptions.map((opt) {
                  final sel = _selectedInterests.contains(opt.$1);
                  return FilterChip(
                    label: Text(opt.$2),
                    selected: sel,
                    onSelected: (v) => setState(() {
                      if (v && _selectedInterests.length < 5) {
                        _selectedInterests.add(opt.$1);
                      } else {
                        _selectedInterests.remove(opt.$1);
                      }
                    }),
                    selectedColor: _primary.withValues(alpha: 0.14),
                    checkmarkColor: _primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: sel ? const Color(0xFF0F6E56) : null,
                      fontWeight: sel ? FontWeight.w500 : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedInterests.length}/5 seleccionados',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: _primary,
          ),
        ),
      );
}

/// Campo que abre un BottomSheet con lista de opciones.
class _PickerField extends StatelessWidget {
  final String label;
  final String? selected;
  final List<(String, String)> options;
  final void Function(String) onChanged;

  const _PickerField({
    required this.label,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel =
        options.where((o) => o.$1 == selected).firstOrNull?.$2;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E6DF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedLabel ?? 'Seleccionar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedLabel != null
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt.$2),
                trailing: selected == opt.$1
                    ? const Icon(Icons.check_circle, color: _primary)
                    : null,
                onTap: () {
                  onChanged(opt.$1);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Grid 4×4 de tipos MBTI con toggle y botón limpiar.
class _MbtiGrid extends StatelessWidget {
  final String? selected;
  final void Function(String?) onChanged;

  const _MbtiGrid({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MBTI', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 6),
              Text(
                '(opcional)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              if (selected != null)
                TextButton(
                  onPressed: () => onChanged(null),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 2.4,
            children: _mbtis.map((t) {
              final isSel = selected == t;
              return GestureDetector(
                onTap: () => onChanged(isSel ? null : t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSel ? _primary : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSel ? _primary : Colors.grey[300]!,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    t,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isSel ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
}
