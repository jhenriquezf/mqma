import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../../domain/event_model.dart';

class EventDetailScreen extends ConsumerWidget {
  final String id;
  const EventDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del evento')),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Error al cargar el evento')),
        data: (event) => _EventDetailBody(event: event),
      ),
    );
  }
}

class _EventDetailBody extends StatelessWidget {
  final EventModel event;
  const _EventDetailBody({required this.event});

  static const _typeLabels = {
    'dinner': 'Cena', 'lunch': 'Almuerzo', 'coffee': 'Café',
    'drinks': 'Drinks', 'women_only': 'Solo mujeres', 'founders': 'Founders',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canBook = event.status == 'open' && event.spotsLeft > 0;

    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_typeLabels[event.type] ?? event.type,
                  style: const TextStyle(color: Color(0xFF0F6E56), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            Text(event.restaurantName,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(child: Text(event.restaurantAddress,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14))),
            ]),
            const SizedBox(height: 24),
            _row(Icons.calendar_today_outlined, event.eventDate),
            const SizedBox(height: 10),
            _row(Icons.access_time_outlined, event.eventTime),
            const SizedBox(height: 10),
            _row(Icons.people_outline,
                event.spotsLeft > 0 ? '${event.spotsLeft} lugares disponibles' : 'Sin lugares disponibles',
                color: event.spotsLeft == 0 ? Colors.red : null),
            const SizedBox(height: 10),
            _row(Icons.location_city_outlined, event.cityName),
            const SizedBox(height: 24),
            if (event.status != 'open') ...[
              _StatusBanner(status: event.status),
              const SizedBox(height: 24),
            ],
            if (event.notes != null && event.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.notes!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5))),
                ]),
              ),
              const SizedBox(height: 16),
            ],
          ]),
        ),
      ),
      _DetailCTA(event: event, canBook: canBook),
    ]);
  }

  Widget _row(IconData icon, String label, {Color? color}) => Row(children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 15, color: color,
            fontWeight: color != null ? FontWeight.w500 : null)),
      ]);
}

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      'matching'  => (Icons.auto_awesome,        'Armando los grupos\u2026',  Colors.blue),
      'confirmed' => (Icons.check_circle_outline, 'Grupos confirmados',        const Color(0xFF1D9E75)),
      'done'      => (Icons.restaurant,           'Evento finalizado',         Colors.grey),
      _           => (Icons.lock_outline,         'Evento cerrado',            Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      ]),
    );
  }
}

class _DetailCTA extends StatelessWidget {
  final EventModel event;
  final bool canBook;
  const _DetailCTA({required this.event, required this.canBook});

  String _fmt(int p) => p.toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: switch (event.status) {
        'open' => Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Precio por persona',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                Text('\$${_fmt(event.priceCLP)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                        color: Color(0xFF1D9E75))),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: canBook ? () => context.push('/events/${event.id}/book') : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(canBook ? 'Reservar ahora' : 'Sin lugares disponibles',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ]),
        'matching' || 'confirmed' => FilledButton.icon(
            onPressed: () => context.push('/events/${event.id}/group'),
            icon: const Icon(Icons.people_outline, size: 18),
            label: const Text('Ver mi mesa'),
            style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
          ),
        _ => FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              disabledBackgroundColor: Colors.grey[200],
            ),
            child: const Text('Evento finalizado'),
          ),
      },
    );
  }
}
