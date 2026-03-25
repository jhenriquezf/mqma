
from django.urls import path
from .views import (
    CityListView, EventListView, EventDetailView,
    BookingListCreateView, BookingDetailView, CheckinView,
)

urlpatterns = [
    path('', EventListView.as_view(), name='event-list'),
    path('<uuid:pk>/', EventDetailView.as_view(), name='event-detail'),
    path('cities/', CityListView.as_view(), name='city-list'),
    path('bookings/', BookingListCreateView.as_view(), name='booking-list-create'),
    path('bookings/<uuid:pk>/', BookingDetailView.as_view(), name='booking-detail'),
    path('checkin/', CheckinView.as_view(), name='event-checkin'),
]
