import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';

const _primary = Color(0xFF1D9E75);

const _stageLabels = {
  'idea': 'Idea',
  'mvp': 'MVP',
  'early': 'Early stage',
  'growth': 'Growth',
  'scale': 'Scale',
  'executive': 'Ejecutivo',
  'investor': 'Inversor',
};

const _goalLabels = {
  'cofounder': 'Cofundador',
  'clients': 'Clientes',
  'investors': 'Inversores',
  'talent': 'Talento',
  'mentors': 'Mentores',
  'network': 'Expandir red',
  'friends': 'Amigos',
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          profileAsync.maybeWhen(
            data: (p) => p != null
                ? IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar perfil',
                    onPressed: () => context.push('/profile/edit'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: 52, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('No se pudo cargar el perfil'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.read(profileProvider.notifier).refresh(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (profile) => profile == null
            ? const Center(child: Text('Sin perfil'))
            : _ProfileBody(profile: profile),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final ProfileModel profile;
  const _ProfileBody({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final interests = profile.interestTags;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      children: [
        // ── Header: avatar + nombre + email ──────────────────────────────
        _ProfileHeader(profile: profile),
        const SizedBox(height: 20),

        // ── Bio ──────────────────────────────────────────────────────────
        if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
          Text(
            profile.bio!.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Chips de info ─────────────────────────────────────────────────
        _InfoChips(profile: profile),
        const SizedBox(height: 20),

        // ── Intereses ────────────────────────────────────────────────────
        if (interests.isNotEmpty) ...[
          Text(
            'INTERESES',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.9,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests
                .map((t) => _TagChip(tag: t.tag))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],

        // ── LinkedIn ──────────────────────────────────────────────────────
        if (profile.linkedinUrl != null && profile.linkedinUrl!.isNotEmpty) ...[
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.link_rounded, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                profile.linkedinUrl!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF0077B5),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
          const SizedBox(height: 14),
        ],

        // ── NPS promedio ─────────────────────────────────────────────────
        if (profile.npsAvg != null) ...[
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
            const SizedBox(width: 6),
            Text(
              'Valoración promedio: ${profile.npsAvg!.toStringAsFixed(1)}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ]),
          const SizedBox(height: 14),
        ],

        // ── Logout ────────────────────────────────────────────────────────
        const Divider(height: 1),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Cerrar sesión'),
                content: const Text('¿Estás seguro de que quieres salir?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Salir'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              await ref.read(authStateProvider.notifier).logout();
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar con iniciales
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Text(
              profile.initials,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.displayName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                profile.email,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (profile.industry != null &&
                  profile.industry!.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  profile.industry!.trim(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChips extends StatelessWidget {
  final ProfileModel profile;
  const _InfoChips({required this.profile});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (profile.stage != null) {
      chips.add(_InfoPill(
        icon: Icons.trending_up_rounded,
        label: _stageLabels[profile.stage] ?? profile.stage!,
        color: _primary,
      ));
    }
    if (profile.lookingFor != null) {
      chips.add(_InfoPill(
        icon: Icons.search_rounded,
        label: _goalLabels[profile.lookingFor] ?? profile.lookingFor!,
        color: const Color(0xFF6366F1),
      ));
    }
    if (profile.mbti != null) {
      chips.add(_InfoPill(
        icon: Icons.psychology_outlined,
        label: profile.mbti!,
        color: const Color(0xFFF59E0B),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      );
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          _capitalize(tag),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F6E56),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
