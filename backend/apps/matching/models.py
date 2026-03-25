import uuid
from django.db import models


class MatchGroup(models.Model):
    STATUS_CHOICES = [
        ("proposed", "Propuesto por algoritmo"),
        ("approved", "Aprobado por admin"),
        ("notified", "Notificado a usuarios"),
        ("done", "Completado"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event = models.ForeignKey(
        "events.Event", on_delete=models.CASCADE, related_name="groups"
    )
    score = models.FloatField(default=0.0, help_text="Score calculado por el engine")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default="proposed")
    admin_approved = models.BooleanField(default=False)
    admin_notes = models.TextField(blank=True)
    table_number = models.PositiveSmallIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "grupo"
        verbose_name_plural = "grupos"
        ordering = ["-score"]

    def __str__(self):
        return f"Grupo {self.table_number or self.id} — {self.event}"

    @property
    def members(self):
        return self.bookings.select_related("user__profile")

    def approve(self):
        self.admin_approved = True
        self.status = "approved"
        self.save(update_fields=["admin_approved", "status", "updated_at"])
