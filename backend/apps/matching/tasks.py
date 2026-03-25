
from celery import shared_task
from django.utils import timezone
from apps.events.models import Event, Booking
from apps.matching.models import MatchGroup
from apps.matching.engine import build_groups
from apps.users.models import Profile


@shared_task(name="matching.run_for_event")
def run_matching_for_event(event_id: str):
    try:
        event = Event.objects.get(id=event_id, status="matching")
    except Event.DoesNotExist:
        return {"error": f"Evento {event_id} no encontrado o no en estado matching"}

    bookings = Booking.objects.filter(
        event=event, status="confirmed"
    ).select_related("user__profile")

    profiles = []
    for b in bookings:
        try:
            profiles.append(b.user.profile)
        except Profile.DoesNotExist:
            continue

    if len(profiles) < 4:
        return {"error": "Menos de 4 perfiles confirmados"}

    proposed = build_groups(profiles, group_size=6)
    created = 0
    for i, group_data in enumerate(proposed, start=1):
        mg = MatchGroup.objects.create(
            event=event, score=group_data["score"],
            table_number=i, status="proposed", admin_approved=False,
        )
        profile_ids = [p.user_id for p in group_data["profiles"]]
        Booking.objects.filter(event=event, user_id__in=profile_ids).update(group=mg)
        created += 1

    return {"event": str(event_id), "groups_created": created}


@shared_task(name="matching.notify_group_members")
def notify_group_members(group_id: str):
    """Notifica por FCM a todos los miembros de un grupo aprobado."""
    from apps.users.fcm_service import send_push

    try:
        group = MatchGroup.objects.select_related("event__restaurant").get(
            id=group_id, admin_approved=True
        )
    except MatchGroup.DoesNotExist:
        return {"error": "Grupo no encontrado o no aprobado"}

    restaurant = group.event.restaurant.name if group.event.restaurant else "el restaurante"
    table_info = f"Mesa {group.table_number} · " if group.table_number else ""
    event_date = group.event.event_date.strftime("%-d de %B") if group.event.event_date else ""

    bookings = group.bookings.select_related("user")
    notified = 0

    for booking in bookings:
        sent = send_push(
            booking.user,
            title="¡Tu mesa está confirmada! 🎉",
            body=f"{table_info}{restaurant} · {event_date}",
            data={
                "type": "group_ready",
                "event_id": str(group.event_id),
                "group_id": str(group.id),
            },
        )
        if sent > 0:
            notified += 1

    group.status = "notified"
    group.save(update_fields=["status"])
    return {"group": str(group_id), "notified": notified}


@shared_task(name="matching.run_weekly")
def run_weekly_matching():
    from datetime import timedelta
    upcoming = Event.objects.filter(
        status="open",
        event_date__range=[
            timezone.now().date(),
            timezone.now().date() + timedelta(days=5),
        ],
    )
    results = []
    for event in upcoming:
        event.status = "matching"
        event.save(update_fields=["status"])
        result = run_matching_for_event.delay(str(event.id))
        results.append(str(result.id))
    return {"triggered": results}
