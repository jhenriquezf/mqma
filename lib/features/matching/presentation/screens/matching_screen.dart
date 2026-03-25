import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/matching_provider.dart';
import '../../domain/match_group_model.dart';

const _primary = Color(0xFF1D9E75);
const _primaryDark = Color(0xFF0F6E56);

class MatchingScreen extends ConsumerWidget {
  final String eventId;
  const MatchingScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(matchGroupProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: const Text('Mi mesa')),
      body: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          onRetry: () => ref.invalidate(matchGroupProvider(eventId)),
        ),
        data: (group) => group == null
            ? _WaitingView(
                onRefresh: () => ref.invalidate(matchGroupProvider(eventId)),
              )
            : _GroupView(group: group),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_outlined, size: 52, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Sin conexión',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'No pudimos cargar tu mesa.',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

// ── Waiting ───────────────────────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _WaitingView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height -
              kToolbarHeight -
              kBottomNavigationBarHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono principal
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    size: 44,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Tu mesa está en preparación',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'El equipo está eligiendo tu grupo perfecto.\nSe actualiza automáticamente.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey[600], height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Timeline de pasos
                const _StepRow(
                  icon: Icons.check_circle,
                  color: _primary,
                  label: 'Reserva confirmada',
                  done: true,
                ),
                const _StepDivider(done: true),
                const _StepRow(
                  icon: Icons.group_add_outlined,
                  color: _primary,
                  label: 'Armando tu grupo',
                  done: false,
                  current: true,
                ),
                const _StepDivider(done: false),
                const _StepRow(
                  icon: Icons.celebration_outlined,
                  color: Color(0xFFBDBDBD), // grey[400] como const
                  label: '¡Tu mesa está lista!',
                  done: false,
                ),

                const SizedBox(height: 36),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Verificar ahora'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool done;
  final bool current;

  const _StepRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.done,
    this.current = false,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: current ? FontWeight.w600 : FontWeight.w400,
              color: done || current ? Colors.grey[800] : Colors.grey[400],
            ),
          ),
          if (current) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      );
}

class _StepDivider extends StatelessWidget {
  final bool done;
  const _StepDivider({required this.done});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
        child: Container(
          width: 2,
          height: 20,
          color: done ? _primary.withValues(alpha: 0.4) : Colors.grey[300],
        ),
      );
}

// ── Group ready ───────────────────────────────────────────────────────────────

class _GroupView extends StatelessWidget {
  final MatchGroupModel group;
  const _GroupView({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = group.members.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado de confirmación
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.celebration_outlined,
                    color: _primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Tu mesa está confirmada!',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$count compañero${count == 1 ? '' : 's'} seleccionado${count == 1 ? '' : 's'} para ti',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tarjeta del restaurante
          _MesaInfoCard(group: group),
          const SizedBox(height: 24),

          // Título sección miembros
          Text(
            'Tu grupo',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),

          ...group.members.map((m) => _MemberCard(member: m)),
        ],
      ),
    );
  }
}

// ── Mesa info card ────────────────────────────────────────────────────────────

class _MesaInfoCard extends StatelessWidget {
  final MatchGroupModel group;
  const _MesaInfoCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de mesa
          Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.white70, size: 15),
              const SizedBox(width: 6),
              Text(
                group.tableNumber != null
                    ? 'Mesa ${group.tableNumber}'
                    : 'Tu mesa',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            group.restaurantName,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (group.restaurantAddress.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              group.restaurantAddress,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _infoChip(Icons.calendar_today_outlined, group.eventDate),
              const SizedBox(width: 16),
              _infoChip(Icons.access_time_outlined, group.eventTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      );
}

// ── Member card ───────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final MatchMemberModel member;
  const _MemberCard({required this.member});

  static const _stageLabels = {
    'idea': 'Idea',
    'mvp': 'MVP',
    'early': 'Early stage',
    'growth': 'Growth',
    'scale': 'Scale',
    'executive': 'Ejecutivo',
    'investor': 'Inversor',
    'other': 'Otro',
  };

  static const _lookingForLabels = {
    'cofounder': 'Cofundador',
    'clients': 'Clientes',
    'investors': 'Inversores',
    'talent': 'Talento',
    'mentors': 'Mentores',
    'network': 'Expandir red',
    'friends': 'Amigos',
  };

  // Paleta de colores para avatares (determinista por nombre)
  static const _avatarColors = [
    Color(0xFF1D9E75),
    Color(0xFF2E86AB),
    Color(0xFFE84855),
    Color(0xFFF4A261),
    Color(0xFF7B2D8B),
    Color(0xFF3D405B),
  ];

  Color _avatarColor() {
    if (member.name.isEmpty) return _avatarColors[0];
    return _avatarColors[member.name.codeUnitAt(0) % _avatarColors.length];
  }

  String _initials() {
    final parts = member.name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final stageLabel = _stageLabels[member.stage];
    final lookingForLabel = _lookingForLabels[member.lookingFor];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar con iniciales
            CircleAvatar(
              radius: 24,
              backgroundColor: _avatarColor(),
              child: Text(
                _initials(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    member.name.isNotEmpty ? member.name : 'Compañero',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (member.industry.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      member.industry,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // Chips: etapa + MBTI
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (stageLabel != null)
                        _Chip(
                          label: stageLabel,
                          bg: _primary.withValues(alpha: 0.1),
                          fg: _primaryDark,
                        ),
                      if (member.mbti != null)
                        _Chip(
                          label: member.mbti!,
                          bg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          fg: const Color(0xFF92400E),
                        ),
                    ],
                  ),
                  // Objetivo
                  if (lookingForLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.search, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Busca: $lookingForLabel',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: fg,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
