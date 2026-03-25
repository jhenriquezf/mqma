
from rest_framework import serializers
from .models import Payment


class PaymentSerializer(serializers.ModelSerializer):
    booking_id = serializers.UUIDField(source='booking.id', read_only=True)
    event_date = serializers.DateField(source='booking.event.event_date', read_only=True)
    restaurant = serializers.CharField(source='booking.event.restaurant.name', read_only=True)

    class Meta:
        model = Payment
        fields = [
            'id', 'booking_id', 'event_date', 'restaurant',
            'provider', 'amount', 'currency', 'status', 'paid_at', 'created_at',
        ]
        read_only_fields = fields


class PaymentInitSerializer(serializers.Serializer):
    """Inicia un pago para una reserva pendiente."""
    booking_id = serializers.UUIDField()
    provider = serializers.ChoiceField(choices=['flow', 'mercadopago'], default='flow')

    def validate_booking_id(self, value):
        from apps.events.models import Booking
        try:
            booking = Booking.objects.select_related(
                'event', 'user'
            ).get(id=value, user=self.context['request'].user)
        except Booking.DoesNotExist:
            raise serializers.ValidationError('Reserva no encontrada.')
        if booking.status != 'pending':
            raise serializers.ValidationError('La reserva no está pendiente de pago.')
        if hasattr(booking, 'payment') and booking.payment.status == 'paid':
            raise serializers.ValidationError('Ya fue pagada.')
        self.context['booking'] = booking
        return value
