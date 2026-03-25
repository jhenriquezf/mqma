
from django.urls import path
from .views import (
    PaymentListView, PaymentDetailView,
    PaymentInitView, FlowWebhookView, PaymentStatusView,
)

urlpatterns = [
    path('', PaymentListView.as_view(), name='payment-list'),
    path('<uuid:pk>/', PaymentDetailView.as_view(), name='payment-detail'),
    path('init/', PaymentInitView.as_view(), name='payment-init'),
    path('status/', PaymentStatusView.as_view(), name='payment-status'),
    path('webhook/flow/', FlowWebhookView.as_view(), name='flow-webhook'),
]
