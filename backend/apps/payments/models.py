import uuid
from django.db import models


class Payment(models.Model):
    PROVIDER_CHOICES = [
        ("flow", "Flow"),
        ("mercadopago", "MercadoPago"),
        ("manual", "Manual"),
    ]

    STATUS_CHOICES = [
        ("pending", "Pendiente"),
        ("paid", "Pagado"),
        ("failed", "Fallido"),
        ("refunded", "Reembolsado"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.OneToOneField(
        "events.Booking", on_delete=models.CASCADE, related_name="payment"
    )
    provider = models.CharField(max_length=20, choices=PROVIDER_CHOICES, default="flow")
    provider_id = models.CharField(max_length=120, blank=True, help_text="ID externo del proveedor")
    amount = models.PositiveIntegerField(help_text="Monto en moneda local (entero)")
    currency = models.CharField(max_length=3, default="CLP")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="pending")
    paid_at = models.DateTimeField(null=True, blank=True)
    raw_response = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "pago"
        verbose_name_plural = "pagos"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.provider} {self.amount} {self.currency} — {self.status}"
