from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.matching.admin_views import MatchingPanelView

urlpatterns = [
    path("admin/matching/panel/", MatchingPanelView.as_view(), name="matching-panel"),
    path("admin/", admin.site.urls),
    path("api/v1/auth/", include("dj_rest_auth.urls")),
    path("api/v1/auth/registration/", include("dj_rest_auth.registration.urls")),
    path("api/v1/users/", include("apps.users.urls")),
    path("api/v1/events/", include("apps.events.urls")),
    path("api/v1/matching/", include("apps.matching.urls")),
    path("api/v1/payments/", include("apps.payments.urls")),
    path("api/v1/reviews/", include("apps.reviews.urls")),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
