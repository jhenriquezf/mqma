
from django.urls import path
from .views import (
    MyGroupView,
    AdminGroupListView,
    AdminGroupDetailView,
    AdminApproveGroupView,
    AdminRunMatchingView,
)

urlpatterns = [
    path('my-group/', MyGroupView.as_view(), name='my-group'),
    path('admin/groups/', AdminGroupListView.as_view(), name='admin-group-list'),
    path('admin/groups/<uuid:pk>/', AdminGroupDetailView.as_view(), name='admin-group-detail'),
    path('admin/groups/<uuid:pk>/approve/', AdminApproveGroupView.as_view(), name='admin-group-approve'),
    path('admin/run/', AdminRunMatchingView.as_view(), name='admin-run-matching'),
]
