
from rest_framework import serializers
from .models import MatchGroup
from apps.users.serializers import ProfileSerializer


class MatchMemberSerializer(serializers.Serializer):
    """Miembro de un grupo — datos visibles para los compañeros de mesa."""
    user_id = serializers.UUIDField(source='user.id')
    name = serializers.CharField(source='user.profile.name', default='')
    industry = serializers.CharField(source='user.profile.industry', default='')
    stage = serializers.CharField(source='user.profile.stage', default='')
    looking_for = serializers.CharField(source='user.profile.looking_for', default='')
    mbti = serializers.CharField(source='user.profile.mbti', default='')


class MatchGroupPublicSerializer(serializers.ModelSerializer):
    """
    Lo que ve el usuario en la app: su grupo asignado sin scores ni datos admin.
    Solo disponible después de que el admin aprueba y notifica.
    """
    members = serializers.SerializerMethodField()
    event_date = serializers.DateField(source='event.event_date', read_only=True)
    event_time = serializers.TimeField(source='event.event_time', read_only=True)
    restaurant_name = serializers.CharField(source='event.restaurant.name', read_only=True)
    restaurant_address = serializers.CharField(source='event.restaurant.address', read_only=True)
    table_number = serializers.IntegerField(read_only=True)

    class Meta:
        model = MatchGroup
        fields = [
            'id', 'table_number', 'event_date', 'event_time',
            'restaurant_name', 'restaurant_address', 'members',
        ]

    def get_members(self, obj):
        bookings = obj.bookings.select_related(
            'user__profile'
        ).exclude(user=self.context['request'].user)
        return MatchMemberSerializer(bookings, many=True).data


class MatchGroupAdminSerializer(serializers.ModelSerializer):
    """Panel admin — incluye score, estado y capacidad de aprobación."""
    members = serializers.SerializerMethodField()
    event_info = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = MatchGroup
        fields = [
            'id', 'event', 'event_info', 'table_number', 'score',
            'status', 'admin_approved', 'admin_notes',
            'member_count', 'members', 'created_at',
        ]
        read_only_fields = ['id', 'score', 'created_at']

    def get_members(self, obj):
        bookings = obj.bookings.select_related('user__profile')
        return MatchMemberSerializer(bookings, many=True).data

    def get_event_info(self, obj):
        return {
            'date': str(obj.event.event_date),
            'city': obj.event.city.name,
            'restaurant': obj.event.restaurant.name if obj.event.restaurant else '',
        }

    def get_member_count(self, obj):
        return obj.bookings.count()
