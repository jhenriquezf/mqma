
from django.urls import path
from .views import ReviewListCreateView, ReviewDetailView, EventReviewStatsView

urlpatterns = [
    path('', ReviewListCreateView.as_view(), name='review-list-create'),
    path('<uuid:pk>/', ReviewDetailView.as_view(), name='review-detail'),
    path('stats/', EventReviewStatsView.as_view(), name='review-stats'),
]
