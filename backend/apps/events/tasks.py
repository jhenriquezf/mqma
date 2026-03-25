from celery import shared_task
from django.utils import timezone
from datetime import timedelta


@shared_task(name="events.send_reminders")
def send_event_reminders():
    """Envía recordatorio 24h y 2h antes del evento."""
    from apps.events.models import Booking

    now = timezone.now()
    windows = [
        ("24h", now + timedelta(hours=23), now + timedelta(hours=25)),
        ("2h", now + timedelta(hours=1, minutes=50), now + timedelta(hours=2, minutes=10)),
    ]

    for label, start, end in windows:
        bookings = Booking.objects.filter(
            status="confirmed",
            event__event_date__range=[start.date(), end.date()],
        ).select_related("user", "event__restaurant")

        for booking in bookings:
            _send_reminder_notification.delay(str(booking.id), label)


@shared_task(name="events.send_reminder_notification")
def _send_reminder_notification(booking_id: str, window: str):
    from apps.events.models import Booking
    from apps.users.fcm_service import send_push

    try:
        booking = Booking.objects.select_related(
            "user", "event__restaurant", "group"
        ).get(id=booking_id)
    except Booking.DoesNotExist:
        return

    restaurant = booking.event.restaurant.name if booking.event.restaurant else "el restaurante"
    label = "en 24 horas" if window == "24h" else "en 2 horas"

    send_push(
        booking.user,
        title=f"Tu evento es {label} 🍽️",
        body=f"{restaurant} · {booking.event.event_date.strftime('%-d de %B')}",
        data={
            "type": "reminder",
            "event_id": str(booking.event_id),
            "window": window,
        },
    )


@shared_task(name="events.send_post_event_nps")
def send_post_event_nps():
    """Envía solicitud de NPS 2h después de cada evento terminado."""
    from apps.events.models import Event, Booking

    cutoff_start = timezone.now() - timedelta(hours=3)
    cutoff_end = timezone.now() - timedelta(hours=1)

    events = Event.objects.filter(
        status="confirmed",
        event_date=timezone.now().date(),
    )
    for event in events:
        bookings = Booking.objects.filter(event=event, status="attended").select_related("user")
        from apps.users.fcm_service import send_push
        for booking in bookings:
            send_push(
                booking.user,
                title="¿Cómo estuvo tu mesa? ⭐",
                body="Déjanos tu valoración del evento. ¡Solo toma 1 minuto!",
                data={
                    "type": "review_request",
                    "event_id": str(event.id),
                },
            )
        event.status = "done"
        event.save(update_fields=["status"])
