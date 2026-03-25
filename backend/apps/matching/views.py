
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from .models import MatchGroup
from .serializers import MatchGroupPublicSerializer, MatchGroupAdminSerializer
from apps.events.models import Booking


class MyGroupView(APIView):
    """
    GET /matching/my-group/?event=<id>
    El usuario ve los compañeros de mesa una vez el grupo está aprobado.
    Incluye 'approved' para que funcione aunque Celery no haya enviado notificaciones.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        event_id = request.query_params.get('event')
        if not event_id:
            return Response({'detail': 'Parámetro event requerido.'}, status=400)

        booking = Booking.objects.filter(
            user=request.user,
            event_id=event_id,
            group__isnull=False,
            group__status__in=['approved', 'notified', 'done'],
        ).select_related('group__event__restaurant', 'group__event__city').first()

        if not booking:
            return Response({'detail': 'Grupo no disponible aún.'}, status=404)

        serializer = MatchGroupPublicSerializer(
            booking.group, context={'request': request}
        )
        return Response(serializer.data)


class AdminGroupListView(generics.ListAPIView):
    """
    GET /matching/admin/groups/?event=<id>&status=proposed
    Panel admin — listado de grupos para aprobación.
    """
    serializer_class = MatchGroupAdminSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['event', 'status', 'admin_approved']
    pagination_class = None  # Panel admin carga todos los grupos de una vez

    def get_queryset(self):
        return MatchGroup.objects.select_related(
            'event__city', 'event__restaurant'
        ).prefetch_related(
            'bookings__user__profile'
        ).order_by('-score')


class AdminGroupDetailView(generics.RetrieveUpdateAPIView):
    """
    GET/PATCH /matching/admin/groups/:id/
    Admin puede editar notas, table_number y admin_approved.
    """
    serializer_class = MatchGroupAdminSerializer
    permission_classes = [permissions.IsAdminUser]
    queryset = MatchGroup.objects.all()

    def partial_update(self, request, *args, **kwargs):
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)


class AdminApproveGroupView(APIView):
    """
    POST /matching/admin/groups/:id/approve/
    Aprueba el grupo y dispara notificaciones a los miembros.
    """
    permission_classes = [permissions.IsAdminUser]

    def post(self, request, pk):
        try:
            group = MatchGroup.objects.get(pk=pk)
        except MatchGroup.DoesNotExist:
            return Response({'detail': 'No encontrado.'}, status=404)

        if group.admin_approved:
            return Response({'detail': 'Ya aprobado.'}, status=400)

        group.approve()

        # Disparar notificaciones async
        from apps.matching.tasks import notify_group_members
        notify_group_members.delay(str(group.id))

        return Response({'detail': f'Grupo {group.table_number} aprobado y notificaciones enviadas.'})


class AdminRunMatchingView(APIView):
    """
    POST /matching/admin/run/?event=<id>
    Ejecuta el engine de matching para un evento.
    """
    permission_classes = [permissions.IsAdminUser]

    def post(self, request):
        event_id = request.query_params.get('event')
        if not event_id:
            return Response({'detail': 'Parámetro event requerido.'}, status=400)
        from apps.matching.tasks import run_matching_for_event
        task = run_matching_for_event.delay(event_id)
        return Response({'task_id': task.id, 'detail': 'Matching iniciado.'})
