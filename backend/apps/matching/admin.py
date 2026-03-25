from django.contrib import admin
from django.utils.html import format_html
from unfold.admin import ModelAdmin, TabularInline
from unfold.decorators import action
from .models import MatchGroup


class BookingInline(TabularInline):
    from apps.events.models import Booking
    model = Booking
    fields = ["user", "status", "checked_in"]
    readonly_fields = ["user", "checked_in"]
    extra = 0
    can_delete = False


@admin.register(MatchGroup)
class MatchGroupAdmin(ModelAdmin):
    list_display = [
        "event", "table_number", "score_display",
        "member_count", "status_badge", "admin_approved"
    ]
    list_filter = ["status", "admin_approved", "event__city"]
    search_fields = ["event__city__name"]
    readonly_fields = ["score", "created_at", "updated_at"]
    inlines = [BookingInline]

    actions_detail = ["approve_group"]

    @action(description="Aprobar grupo")
    def approve_group(self, request, object_id):
        group = MatchGroup.objects.get(pk=object_id)
        group.approve()
        from django.contrib import messages
        messages.success(request, f"Grupo {group.table_number} aprobado.")

    def score_display(self, obj):
        pct = int(obj.score * 100)
        color = "#1D9E75" if pct >= 70 else "#BA7517" if pct >= 50 else "#E24B4A"
        return format_html(
            '<span style="color:{}; font-weight:500">{:.0f}%</span>', color, pct
        )
    score_display.short_description = "Score"

    def member_count(self, obj):
        return obj.bookings.count()
    member_count.short_description = "Miembros"

    def status_badge(self, obj):
        colors = {
            "proposed": "#7F77DD",
            "approved": "#1D9E75",
            "notified": "#BA7517",
            "done": "#888780",
        }
        color = colors.get(obj.status, "#888780")
        return format_html(
            '<span style="background:{}20; color:{}; padding:2px 8px; '
            'border-radius:4px; font-size:12px">{}</span>',
            color, color, obj.get_status_display()
        )
    status_badge.short_description = "Estado"
