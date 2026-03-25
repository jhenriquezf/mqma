
from django.urls import path
from .views import MeView, ProfileDetailView, ProfileTagView, DeviceTokenView

urlpatterns = [
    path('me/', MeView.as_view(), name='user-me'),
    path('profile/', ProfileDetailView.as_view(), name='user-profile'),
    path('profile/tags/', ProfileTagView.as_view(), name='user-profile-tags'),
    path('device-token/', DeviceTokenView.as_view(), name='user-device-token'),
]
