from django.contrib import admin as admin_site
from django.contrib.admin.views.decorators import staff_member_required
from django.utils.decorators import method_decorator
from django.views.generic import TemplateView
from apps.events.models import Event


@method_decorator(staff_member_required, name="dispatch")
class MatchingPanelView(TemplateView):
    template_name = "admin/matching_panel.html"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        # Contexto completo del admin (sidebar, nav, has_permission, etc.)
        ctx.update(admin_site.site.each_context(self.request))
        ctx["title"] = "Panel de Matching"
        ctx["events"] = Event.objects.filter(
            status__in=["open", "matching", "confirmed"]
        ).select_related("city").order_by("-event_date")
        return ctx
