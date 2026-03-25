
from django.utils import timezone
from rest_framework import generics, permissions, status, filters
from rest_framework.response import Response
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from .models import City, Restaurant, Event, Booking
from .serializers import (
    CitySerializer, RestaurantSerializer,
    EventListSerializer, EventDetailSerializer,
    BookingSerializer, CheckinSerializer,
)


class IsAdminOrReadOnly(permissions.BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return request.user.is_authenticated
        return request.user.is_staff


class CityListView(generics.ListAPIView):
    """GET /events/cities/ — ciudades activas."""
    queryset = City.objects.filter(active=True).order_by('country', 'name')
    serializer_class = CitySerializer
    permission_classes = [permissions.IsAuthenticated]


class EventListView(generics.ListAPIView):
    """GET /events/ — eventos abiertos con filtros."""
    serializer_class = EventListSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['city', 'type', 'status', 'event_date']
    ordering_fields = ['event_date', 'price_clp']
    ordering = ['event_date']

    def get_queryset(self):
        return Event.objects.filter(
            status__in=['open', 'confirmed'],
            event_date__gte=timezone.now().date(),
        ).select_related('city', 'restaurant').order_by('event_date')


class EventDetailView(generics.RetrieveAPIView):
    """GET /events/:id/ — detalle de un evento."""
    serializer_class = EventDetailSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Event.objects.select_related('city', 'restaurant')


class BookingListCreateView(generics.ListCreateAPIView):
    """GET /events/bookings/ — mis reservas. POST — crear reserva."""
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Booking.objects.filter(
            user=self.request.user
        ).select_related('event__city', 'event__restaurant', 'payment').order_by('-created_at')


class BookingDetailView(generics.RetrieveDestroyAPIView):
    """GET /events/bookings/:id/ — detalle. DELETE — cancelar."""
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user)

    def perform_destroy(self, instance):
        if instance.status == 'confirmed':
            instance.status = 'cancelled'
            instance.save(update_fields=['status'])
        else:
            instance.delete()


class CheckinView(APIView):
    """POST /events/checkin/ — validar QR y registrar asistencia."""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CheckinSerializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        booking = serializer.context['booking']
        if booking.checked_in:
            return Response({'detail': 'Ya registrado.'}, status=400)
        booking.checked_in = True
        booking.checked_in_at = timezone.now()
        booking.status = 'attended'
        booking.save(update_fields=['checked_in', 'checked_in_at', 'status'])
        return Response({'detail': 'Check-in registrado.', 'booking_id': str(booking.id)})
