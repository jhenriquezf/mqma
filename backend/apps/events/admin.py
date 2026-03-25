
from django.contrib import admin
from django.utils.html import format_html
from unfold.admin import ModelAdmin, TabularInline
from .models import City, Restaurant, Event, Booking


class BookingInline(TabularInline):
    model = Booking
    fields = ['user', 'status', 'checked_in', 'group']
    readonly_fields = ['user', 'checked_in', 'group']
    extra = 0
    can_delete = False


@admin.register(City)
class CityAdmin(ModelAdmin):
    list_display = ['name', 'country', 'active', 'min_users']
    list_filter = ['active', 'country']
    search_fields = ['name', 'country']


@admin.register(Restaurant)
class RestaurantAdmin(ModelAdmin):
    list_display = ['name', 'city', 'avg_price_clp', 'active']
    list_filter = ['city', 'active']
    search_fields = ['name', 'address']


@admin.register(Event)
class EventAdmin(ModelAdmin):
    list_display = ['__str__', 'city', 'event_date', 'event_time', 'status_badge', 'spots_badge']
    list_filter = ['status', 'type', 'city']
    search_fields = ['restaurant__name', 'city__name']
    date_hierarchy = 'event_date'
    inlines = [BookingInline]

    def status_badge(self, obj):
        colors = {
            'draft': '#888780', 'open': '#1D9E75', 'matching': '#BA7517',
            'confirmed': '#378ADD', 'done': '#444441', 'cancelled': '#E24B4A',
        }
        c = colors.get(obj.status, '#888780')
        return format_html('<span style="color:{};font-weight:500">{}</span>', c, obj.get_status_display())
    status_badge.short_description = 'Estado'

    def spots_badge(self, obj):
        left = obj.spots_left
        color = '#1D9E75' if left > 3 else '#BA7517' if left > 0 else '#E24B4A'
        return format_html('<span style="color:{}">{}/{}</span>', color, left, obj.capacity)
    spots_badge.short_description = 'Lugares'


@admin.register(Booking)
class BookingAdmin(ModelAdmin):
    list_display = ['user', 'event', 'status', 'checked_in', 'created_at']
    list_filter = ['status', 'checked_in', 'event__city']
    search_fields = ['user__email', 'event__restaurant__name']
    readonly_fields = ['created_at']
