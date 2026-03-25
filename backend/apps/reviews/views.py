
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Avg, Count, Q
from .models import Review
from .serializers import ReviewSerializer, ReviewStatsSerializer


class ReviewListCreateView(generics.ListCreateAPIView):
    """GET /reviews/ — mis reviews. POST — crear review."""
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Review.objects.filter(
            user=self.request.user
        ).select_related('event__restaurant').order_by('-created_at')


class ReviewDetailView(generics.RetrieveAPIView):
    """GET /reviews/:id/ — detalle de una review."""
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Review.objects.filter(user=self.request.user)


class EventReviewStatsView(APIView):
    """
    GET /reviews/stats/?event=<id>
    Estadísticas NPS de un evento — solo admin.
    """
    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        event_id = request.query_params.get('event')
        if not event_id:
            return Response({'detail': 'Parámetro event requerido.'}, status=400)

        qs = Review.objects.filter(event_id=event_id)
        total = qs.count()
        if total == 0:
            return Response({'detail': 'Sin reviews para este evento.'}, status=404)

        agg = qs.aggregate(
            avg_nps=Avg('nps_score'),
            avg_group=Avg('group_rating'),
            would_return=Count('id', filter=Q(would_return=True)),
            promoters=Count('id', filter=Q(nps_score__gte=9)),
            passives=Count('id', filter=Q(nps_score__gte=7, nps_score__lte=8)),
            detractors=Count('id', filter=Q(nps_score__lte=6)),
        )

        promoter_pct = agg['promoters'] / total * 100
        detractor_pct = agg['detractors'] / total * 100

        data = {
            'event_id': event_id,
            'total_reviews': total,
            'avg_nps': round(agg['avg_nps'] or 0, 1),
            'avg_group_rating': round(agg['avg_group'] or 0, 1),
            'would_return_pct': round(agg['would_return'] / total * 100, 1),
            'promoters': agg['promoters'],
            'passives': agg['passives'],
            'detractors': agg['detractors'],
            'nps_score': round(promoter_pct - detractor_pct, 1),
        }
        serializer = ReviewStatsSerializer(data)
        return Response(serializer.data)
