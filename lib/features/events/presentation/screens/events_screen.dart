import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Próximas mesas'),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {})],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Sin conexión'),
          TextButton(onPressed: () => ref.invalidate(eventsProvider), child: const Text('Reintentar')),
        ])),
        data: (events) {
          if (events.isEmpty) return const Center(child: Text('No hay eventos disponibles en tu ciudad'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(eventsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (_, i) => EventCard(event: events[i], onTap: () => context.push('/events/${events[i].id}')),
            ),
          );
        },
      ),
    );
  }
}
