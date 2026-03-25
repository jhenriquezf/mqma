
from rest_framework import serializers
from .models import Review
from apps.events.models import Booking


class ReviewSerializer(serializers.ModelSerializer):
    event_date = serializers.DateField(source='event.event_date', read_only=True)
    restaurant = serializers.CharField(source='event.restaurant.name', read_only=True)

    class Meta:
        model = Review
        fields = [
            'id', 'event', 'event_date', 'restaurant',
            'nps_score', 'group_rating', 'comment',
            'would_return', 'created_at',
        ]
        read_only_fields = ['id', 'created_at']

    def validate_event(self, value):
        user = self.context['request'].user
        attended = Booking.objects.filter(
            user=user, event=value, status='attended'
        ).exists()
        if not attended:
            raise serializers.ValidationError(
                'Solo puedes dejar review de eventos a los que asististe.'
            )
        if Review.objects.filter(user=user, event=value).exists():
            raise serializers.ValidationError('Ya dejaste una review para este evento.')
        return value

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        review = super().create(validated_data)
        self._update_profile_nps(review)
        return review

    def _update_profile_nps(self, review):
        from apps.users.models import Profile
        from django.db.models import Avg
        try:
            profile = review.user.profile
            avg = Review.objects.filter(user=review.user).aggregate(
                avg=Avg('nps_score')
            )['avg'] or 0
            profile.nps_avg = round(avg, 2)
            profile.save(update_fields=['nps_avg'])
        except Exception:
            pass


class ReviewStatsSerializer(serializers.Serializer):
    """Estadísticas de NPS de un evento — visible para admin."""
    event_id = serializers.UUIDField()
    total_reviews = serializers.IntegerField()
    avg_nps = serializers.FloatField()
    avg_group_rating = serializers.FloatField()
    would_return_pct = serializers.FloatField()
    promoters = serializers.IntegerField()
    passives = serializers.IntegerField()
    detractors = serializers.IntegerField()
    nps_score = serializers.FloatField(help_text='NPS real: %promotores - %detractores')
