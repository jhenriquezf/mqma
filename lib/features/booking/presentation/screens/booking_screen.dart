import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/payment_provider.dart';
import '../../../events/domain/event_model.dart';
import '../../../events/presentation/providers/events_provider.dart';

// ── Pantalla principal ────────────────────────────────────────────────────────

class BookingScreen extends ConsumerWidget {
  final String eventId;
  const BookingScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final payState = ref.watch(paymentFlowProvider);

    return PopScope(
      // Bloquear back durante loading para evitar estado inconsistente
      canPop: !payState.isLoading && payState.step != PaymentStep.awaitingPayment,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleForStep(payState.step)),
          automaticallyImplyLeading:
              payState.step != PaymentStep.awaitingPayment,
        ),
        body: eventAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Error al cargar el evento')),
          data: (event) => _bodyForState(context, ref, event, payState),
        ),
      ),
    );
  }

  String _titleForStep(PaymentStep step) => switch (step) {
        PaymentStep.idle => 'Confirmar reserva',
        PaymentStep.creatingBooking => 'Creando reserva…',
        PaymentStep.initializingPayment => 'Iniciando pago…',
        PaymentStep.awaitingPayment => 'Completar pago',
        PaymentStep.paid => '¡Reserva confirmada!',
        PaymentStep.failed => 'No se pudo completar',
      };

  Widget _bodyForState(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    PaymentFlowState payState,
  ) {
    return switch (payState.step) {
      PaymentStep.idle => _BookingForm(
          event: event,
          onConfirm: () =>
              ref.read(paymentFlowProvider.notifier).startFlow(eventId),
        ),
      PaymentStep.creatingBooking => const _StepLoadingView(
          message: 'Reservando tu lugar…',
        ),
      PaymentStep.initializingPayment => const _StepLoadingView(
          message: 'Iniciando pago con Flow…',
        ),
      PaymentStep.awaitingPayment => _AwaitingPaymentView(
          onCheckNow: () =>
              ref.read(paymentFlowProvider.notifier).checkNow(),
          onReopen: () =>
              ref.read(paymentFlowProvider.notifier).reopenBrowser(),
        ),
      PaymentStep.paid => _SuccessView(
          onDone: () {
            ref.read(paymentFlowProvider.notifier).reset();
            context.go('/events');
          },
        ),
      PaymentStep.failed => _FailedView(
          message: payState.errorMessage,
          onRetry: () => ref.read(paymentFlowProvider.notifier).reset(),
          onBack: () {
            ref.read(paymentFlowProvider.notifier).reset();
            context.pop();
          },
        ),
    };
  }
}

// ── Formulario de reserva ─────────────────────────────────────────────────────

class _BookingForm extends StatelessWidget {
  final EventModel event;
  final VoidCallback onConfirm;
  const _BookingForm({required this.event, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EventSummaryCard(event: event),
                const SizedBox(height: 24),
                const _ProcessSteps(),
                if (event.notes != null && event.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _NotesCard(notes: event.notes!),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _BottomCTA(price: event.priceCLP, onConfirm: onConfirm),
      ],
    );
  }
}

// ── Loading intermedio ────────────────────────────────────────────────────────

class _StepLoadingView extends StatelessWidget {
  final String message;
  const _StepLoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(message, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

// ── Esperando pago (browser abierto) ─────────────────────────────────────────

class _AwaitingPaymentView extends StatelessWidget {
  final VoidCallback onCheckNow;
  final VoidCallback onReopen;
  const _AwaitingPaymentView(
      {required this.onCheckNow, required this.onReopen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.open_in_browser_rounded,
              size: 44,
              color: Color(0xFF1D9E75),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Completa el pago en Flow',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Se ha abierto el navegador con la página de pago.\n'
            'Una vez que pagues, regresa aquí.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey[600], height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Verificando automáticamente…',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onCheckNow,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('Ya pagué — Verificar ahora'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onReopen,
            icon: const Icon(Icons.open_in_new, size: 18),
            label: const Text('Volver a abrir Flow'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Pago seguro procesado por Flow Chile.',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Pago exitoso ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final VoidCallback onDone;
  const _SuccessView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 50,
              color: Color(0xFF1D9E75),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '¡Pago exitoso!',
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tu reserva está confirmada.\n'
            'Te avisaremos cuando tu mesa esté lista.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: onDone,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Ver eventos'),
          ),
        ],
      ),
    );
  }
}

// ── Pago fallido ──────────────────────────────────────────────────────────────

class _FailedView extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _FailedView(
      {this.message, required this.onRetry, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'No se pudo completar',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style:
                  TextStyle(color: Colors.grey[600], height: 1.5, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 40),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text('Intentar de nuevo'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onBack,
            child: const Text('Volver al evento'),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta resumen del evento ────────────────────────────────────────────────

class _EventSummaryCard extends StatelessWidget {
  final EventModel event;
  const _EventSummaryCard({required this.event});

  static const _typeLabels = {
    'dinner': 'Cena',
    'lunch': 'Almuerzo',
    'coffee': 'Café',
    'drinks': 'Drinks',
    'women_only': 'Solo mujeres',
    'founders': 'Founders',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _typeLabels[event.type] ?? event.type,
                style: const TextStyle(
                  color: Color(0xFF0F6E56),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.restaurantName,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.restaurantAddress,
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _infoRow(Icons.calendar_today_outlined, event.eventDate),
            const SizedBox(height: 8),
            _infoRow(Icons.access_time_outlined, event.eventTime),
            const SizedBox(height: 8),
            _infoRow(
              Icons.people_outline,
              '${event.spotsLeft} lugar${event.spotsLeft == 1 ? '' : 'es'} disponible${event.spotsLeft == 1 ? '' : 's'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      );
}

// ── Pasos del proceso ─────────────────────────────────────────────────────────

class _ProcessSteps extends StatelessWidget {
  const _ProcessSteps();

  static const _steps = [
    (
      icon: Icons.bookmark_added_outlined,
      title: 'Tu lugar está separado',
      subtitle: 'Pagas ahora y tu reserva queda confirmada al instante.',
    ),
    (
      icon: Icons.group_outlined,
      title: 'Matching de mesa',
      subtitle:
          'Armamos tu grupo de 6 personas según afinidad, 5 días antes del evento.',
    ),
    (
      icon: Icons.notifications_outlined,
      title: 'Te avisamos',
      subtitle:
          'Recibirás los detalles de tu grupo por email y notificación.',
    ),
    (
      icon: Icons.restaurant_outlined,
      title: '¡A la mesa!',
      subtitle: 'Llega, haz check-in con tu QR y vive la experiencia.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Qué pasa luego?',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...List.generate(_steps.length, (i) {
          final step = _steps[i];
          final isLast = i == _steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D9E75).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon,
                        size: 18, color: const Color(0xFF1D9E75)),
                  ),
                  if (!isLast)
                    Container(
                        width: 2, height: 32, color: Colors.grey[200]),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        step.subtitle,
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ── Notas del evento ──────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notes,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA inferior ──────────────────────────────────────────────────────────────

class _BottomCTA extends StatelessWidget {
  final int price;
  final VoidCallback onConfirm;
  const _BottomCTA({required this.price, required this.onConfirm});

  String _formatPrice(int p) => p
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total a pagar',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(
                '\$${_formatPrice(price)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D9E75),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Pago seguro con Flow',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: const Text(
              'Pagar con Flow',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
