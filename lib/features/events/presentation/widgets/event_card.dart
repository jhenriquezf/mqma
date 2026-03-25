import 'package:flutter/material.dart';
import '../../domain/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  const EventCard({super.key, required this.event, required this.onTap});

  static const _typeLabels = {
    'dinner': 'Cena', 'lunch': 'Almuerzo', 'coffee': 'Café',
    'drinks': 'Drinks', 'women_only': 'Solo mujeres', 'founders': 'Founders',
  };

  String _fmtPrice(int p) => p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final isFull = event.spotsLeft == 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isFull ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF1D9E75).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_typeLabels[event.type] ?? event.type, style: const TextStyle(color: Color(0xFF0F6E56), fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              isFull
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(20)), child: Text('Agotado', style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.w500)))
                  : Text('${event.spotsLeft} lugares', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ]),
            const SizedBox(height: 12),
            Text(event.restaurantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(child: Text(event.restaurantAddress, style: TextStyle(color: Colors.grey[600], fontSize: 13), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(event.eventDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.access_time_outlined, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(event.eventTime, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const Spacer(),
              Text('\$${_fmtPrice(event.priceCLP)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1D9E75))),
            ]),
          ]),
        ),
      ),
    );
  }
}
