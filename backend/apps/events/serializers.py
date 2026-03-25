
from rest_framework import serializers
from .models import City, Restaurant, Event, Booking


class CitySerializer(serializers.ModelSerializer):
    class Meta:
        model = City
        fields = ['id', 'name', 'country', 'timezone', 'active']


class RestaurantSerializer(serializers.ModelSerializer):
    city_name = serializers.CharField(source='city.name', read_only=True)

    class Meta:
        model = Restaurant
        fields = [
            'id', 'city', 'city_name', 'name', 'address',
            'avg_price_clp', 'dietary_options', 'active',
        ]


class EventListSerializer(serializers.ModelSerializer):
    city_name = serializers.CharField(source='city.name', read_only=True)
    restaurant_name = serializers.CharField(source='restaurant.name', read_only=True)
    restaurant_address = serializers.CharField(source='restaurant.address', read_only=True)
    spots_left = serializers.IntegerField(read_only=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)

    class Meta:
        model = Event
        fields = [
            'id', 'city_name', 'restaurant_name', 'restaurant_address',
            'event_date', 'event_time', 'capacity', 'spots_left',
            'price_clp', 'status', 'type', 'type_display',
        ]


class EventDetailSerializer(EventListSerializer):
    restaurant = RestaurantSerializer(read_only=True)

    class Meta(EventListSerializer.Meta):
        fields = EventListSerializer.Meta.fields + ['restaurant', 'notes', 'created_at']


class BookingSerializer(serializers.ModelSerializer):
    event = EventListSerializer(read_only=True)
    event_id = serializers.UUIDField(write_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    payment_status = serializers.CharField(source='payment.status', read_only=True, default=None)

    class Meta:
        model = Booking
        fields = [
            'id', 'event', 'event_id', 'user_email',
            'status', 'payment_status', 'checked_in', 'created_at',
        ]
        read_only_fields = ['id', 'status', 'checked_in', 'created_at']

    def validate_event_id(self, value):
        from .models import Event
        try:
            event = Event.objects.get(id=value, status='open')
        except Event.DoesNotExist:
            raise serializers.ValidationError('Evento no disponible.')
        if event.spots_left <= 0:
            raise serializers.ValidationError('El evento está lleno.')
        return value

    def create(self, validated_data):
        from .models import Event
        event = Event.objects.get(id=validated_data.pop('event_id'))
        user = self.context['request'].user
        if Booking.objects.filter(user=user, event=event).exists():
            raise serializers.ValidationError('Ya tienes una reserva para este evento.')
        return Booking.objects.create(user=user, event=event, **validated_data)


class CheckinSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()

    def validate_booking_id(self, value):
        from .models import Booking
        try:
            booking = Booking.objects.select_related('event').get(id=value, status='confirmed')
        except Booking.DoesNotExist:
            raise serializers.ValidationError('Reserva no encontrada o no confirmada.')
        self.context['booking'] = booking
        return value
