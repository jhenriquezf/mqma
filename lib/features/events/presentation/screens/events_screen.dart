import 'package:dio/dio.dart';
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
        error: (e, _) {
          final isNetErr = e is DioException &&
              (e.type == DioExceptionType.connectionError ||
               e.type == DioExceptionType.connectionTimeout ||
               e.type == DioExceptionType.receiveTimeout);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNetErr ? Icons.wifi_off_outlined : Icons.cloud_off_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(isNetErr ? 'Sin conexión' : 'No se pudieron cargar los eventos'),
                TextButton(
                  onPressed: () => ref.invalidate(eventsProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        },
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
