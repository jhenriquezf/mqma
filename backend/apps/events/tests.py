
from django.test import TestCase
from django.contrib.auth import get_user_model
from apps.events.models import City, Restaurant, Event
from apps.users.models import Profile
import datetime

User = get_user_model()


class EventAPITest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="test@mqma.cl", password="testpass123")
        self.city = City.objects.create(name="Santiago", country="Chile", active=True)
        self.restaurant = Restaurant.objects.create(
            city=self.city, name="Restaurante Test",
            address="Av. Providencia 123", avg_price_clp=15000,
        )
        self.event = Event.objects.create(
            city=self.city, restaurant=self.restaurant,
            event_date=datetime.date.today() + datetime.timedelta(days=7),
            event_time=datetime.time(20, 0),
            capacity=30, price_clp=14900, status="open", type="dinner",
        )

    def test_event_spots_left(self):
        self.assertEqual(self.event.spots_left, 30)

    def test_event_str(self):
        self.assertIn("Santiago", str(self.event))


class BookingAPITest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="book@mqma.cl", password="testpass123")
        self.client.force_login(self.user)

    def test_booking_list_requires_auth(self):
        from django.test import Client
        c = Client()
        response = c.get("/api/v1/events/bookings/")
        self.assertEqual(response.status_code, 401)
