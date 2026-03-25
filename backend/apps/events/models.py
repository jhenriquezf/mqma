import uuid
from django.db import models


class City(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=80)
    country = models.CharField(max_length=80)
    timezone = models.CharField(max_length=50, default="America/Santiago")
    active = models.BooleanField(default=False)
    min_users = models.PositiveIntegerField(default=120)

    class Meta:
        verbose_name = "ciudad"
        verbose_name_plural = "ciudades"
        ordering = ["country", "name"]

    def __str__(self):
        return f"{self.name}, {self.country}"


class Restaurant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    city = models.ForeignKey(City, on_delete=models.CASCADE, related_name="restaurants")
    name = models.CharField(max_length=120)
    address = models.CharField(max_length=200)
    avg_price_clp = models.PositiveIntegerField(help_text="Precio promedio por persona en CLP")
    dietary_options = models.JSONField(default=list, blank=True)
    contact_name = models.CharField(max_length=80, blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)
    active = models.BooleanField(default=True)
    notes = models.TextField(blank=True)

    class Meta:
        verbose_name = "restaurante"
        verbose_name_plural = "restaurantes"

    def __str__(self):
        return f"{self.name} — {self.city.name}"


class Event(models.Model):
    STATUS_CHOICES = [
        ("draft", "Borrador"),
        ("open", "Abierto"),
        ("matching", "En matching"),
        ("confirmed", "Confirmado"),
        ("done", "Realizado"),
        ("cancelled", "Cancelado"),
    ]

    TYPE_CHOICES = [
        ("dinner", "Cena"),
        ("lunch", "Almuerzo"),
        ("coffee", "Café"),
        ("drinks", "Drinks"),
        ("women_only", "Solo mujeres"),
        ("founders", "Founders"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    city = models.ForeignKey(City, on_delete=models.CASCADE, related_name="events")
    restaurant = models.ForeignKey(
        Restaurant, on_delete=models.SET_NULL, null=True, blank=True, related_name="events"
    )
    event_date = models.DateField()
    event_time = models.TimeField()
    capacity = models.PositiveIntegerField(default=30)
    price_clp = models.PositiveIntegerField(default=14900)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="draft")
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default="dinner")
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "evento"
        verbose_name_plural = "eventos"
        ordering = ["-event_date"]

    def __str__(self):
        return f"{self.get_type_display()} — {self.city.name} {self.event_date}"

    @property
    def bookings_confirmed(self):
        return self.bookings.filter(status="confirmed").count()

    @property
    def spots_left(self):
        return self.capacity - self.bookings_confirmed


class Booking(models.Model):
    STATUS_CHOICES = [
        ("pending", "Pendiente pago"),
        ("confirmed", "Confirmado"),
        ("cancelled", "Cancelado"),
        ("no_show", "No se presentó"),
        ("attended", "Asistió"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE, related_name="bookings"
    )
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name="bookings")
    group = models.ForeignKey(
        "matching.MatchGroup",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="bookings",
    )
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    checked_in = models.BooleanField(default=False)
    checked_in_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "event")
        verbose_name = "reserva"
        verbose_name_plural = "reservas"

    def __str__(self):
        return f"{self.user.email} → {self.event}"
