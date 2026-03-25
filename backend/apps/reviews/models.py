import uuid
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Review(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        "users.User", on_delete=models.CASCADE, related_name="reviews"
    )
    event = models.ForeignKey(
        "events.Event", on_delete=models.CASCADE, related_name="reviews"
    )
    nps_score = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(0), MaxValueValidator(10)],
        help_text="0–10, NPS estándar",
    )
    group_rating = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        help_text="1–5 estrellas al grupo",
    )
    comment = models.TextField(blank=True)
    would_return = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "event")
        verbose_name = "review"
        verbose_name_plural = "reviews"

    def __str__(self):
        return f"NPS {self.nps_score} — {self.user.email}"
