import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/booking_with_event_model.dart';
import '../providers/checkin_provider.dart';

String _friendlyError(Object? e) {
  if (e == null) return 'Ocurrió un error inesperado. Intenta de nuevo.';
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Sin conexión. Verifica tu red e intenta de nuevo.';
    }
    final status = e.response?.statusCode;
    if (status == 401) return 'Sesión expirada. Vuelve a iniciar sesión.';
    if (status == 404) return 'Reserva no encontrada.';
    if (status == 400) {
      final detail = e.response?.data?['detail'];
      if (detail != null) return detail.toString();
    }
    return 'Error del servidor. Intenta más tarde.';
  }
  return 'Ocurrió un error inesperado. Intenta de nuevo.';
}

class CheckinScreen extends ConsumerStatefulWidget {
  const CheckinScreen({super.key});

  @override
  ConsumerState<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends ConsumerState<CheckinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'Mi entrada'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Escanear'),
          ],
          indicatorColor: scheme.primary,
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyQrTab(),
          _ScanTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Mi QR ──────────────────────────────────────────────────────────

class _MyQrTab extends ConsumerWidget {
  const _MyQrTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(checkinBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: _friendlyError(e),
        onRetry: () => ref.invalidate(checkinBookingsProvider),
      ),
      data: (bookings) {
        if (bookings.isEmpty) {
          return _EmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _BookingQrCard(booking: bookings[i]),
        );
      },
    );
  }
}

class _BookingQrCard extends StatelessWidget {
  const _BookingQrCard({required this.booking});
  final BookingWithEventModel booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isAttended = booking.checkedIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.event.typeDisplay,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(booking.event.eventDate)} · ${_formatTime(booking.event.eventTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(checkedIn: isAttended, status: booking.status),
              ],
            ),
            if (booking.event.restaurantName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.restaurant_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.event.restaurantName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.event.restaurantAddress ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Opacity(
                  opacity: isAttended ? 0.45 : 1.0,
                  child: QrImageView(
                    data: booking.id,
                    version: QrVersions.auto,
                    size: 200,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1D9E75),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF2C2C2A),
                    ),
                  ),
                ),
              ),
            ),
            if (isAttended) ...[
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: scheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '¡Ya hiciste check-in!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Muestra este QR al llegar al restaurante',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      const months = [
        '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final month = int.parse(parts[1]);
      return '${parts[2]} ${months[month]}';
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String time) {
    try {
      return time.substring(0, 5);
    } catch (_) {
      return time;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.checkedIn, required this.status});
  final bool checkedIn;
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    String label;

    if (checkedIn || status == 'attended') {
      bg = scheme.primary.withValues(alpha: 0.1);
      fg = scheme.primary;
      label = 'Asistió';
    } else if (status == 'confirmed') {
      bg = Colors.blue.withValues(alpha: 0.1);
      fg = Colors.blue.shade700;
      label = 'Confirmado';
    } else {
      bg = Colors.orange.withValues(alpha: 0.1);
      fg = Colors.orange.shade700;
      label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Tab 2: Escanear ───────────────────────────────────────────────────────

class _ScanTab extends ConsumerStatefulWidget {
  const _ScanTab();

  @override
  ConsumerState<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<_ScanTab> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _processing = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final bookingId = barcode!.rawValue!;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuidRegex.hasMatch(bookingId)) return;

    setState(() => _processing = true);
    _scanner.stop();
    ref.read(checkinProvider.notifier).checkin(bookingId);
  }

  void _reset() {
    ref.read(checkinProvider.notifier).reset();
    setState(() => _processing = false);
    _scanner.start();
  }

  @override
  Widget build(BuildContext context) {
    final checkinState = ref.watch(checkinProvider);
    final scheme = Theme.of(context).colorScheme;

    if (checkinState is AsyncData && checkinState.value != null) {
      return _CheckinSuccess(
        bookingId: checkinState.value!,
        onScanAnother: _reset,
      );
    }

    if (checkinState is AsyncError) {
      return _CheckinError(
        message: _friendlyError(checkinState.error),
        onRetry: _reset,
      );
    }

    return Stack(
      children: [
        MobileScanner(controller: _scanner, onDetect: _onDetect),
        CustomPaint(
          painter: _ScanFramePainter(color: scheme.primary),
          child: const SizedBox.expand(),
        ),
        if (checkinState is AsyncLoading)
          Container(
            color: Colors.black54,
            child: const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Apunta al QR de la reserva del usuario',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CheckinSuccess extends StatelessWidget {
  const _CheckinSuccess(
      {required this.bookingId, required this.onScanAnother});
  final String bookingId;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: scheme.primary, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Check-in registrado!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'El usuario ha sido marcado como asistente.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onScanAnother,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear otro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinError extends StatelessWidget {
  const _CheckinError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin reservas confirmadas',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando tu pago sea confirmado, tu entrada aparecerá aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

// ─── Scan frame painter ────────────────────────────────────────────────────

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const frameSize = 220.0;
    const cornerLen = 28.0;
    const strokeW = 4.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - frameSize / 2;
    final top = cy - frameSize / 2;
    final right = cx + frameSize / 2;
    final bottom = cy + frameSize / 2;

    // Dim background except center
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTRB(left, top, right, bottom))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black54);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final corner in [
      (left, top, 1.0, 1.0),
      (right, top, -1.0, 1.0),
      (left, bottom, 1.0, -1.0),
      (right, bottom, -1.0, -1.0),
    ]) {
      final ox = corner.$1;
      final oy = corner.$2;
      final dx = corner.$3;
      final dy = corner.$4;
      canvas.drawLine(Offset(ox, oy), Offset(ox + dx * cornerLen, oy), paint);
      canvas.drawLine(Offset(ox, oy), Offset(ox, oy + dy * cornerLen), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanFramePainter old) => old.color != color;
}
