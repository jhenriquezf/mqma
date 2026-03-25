
from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny
from .models import Payment
from .serializers import PaymentSerializer, PaymentInitSerializer
from .flow_client import create_payment_order, get_payment_status, verify_webhook_signature
from django.conf import settings


class PaymentListView(generics.ListAPIView):
    """GET /payments/ — historial de pagos del usuario."""
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.filter(
            booking__user=self.request.user
        ).select_related(
            'booking__event__restaurant'
        ).order_by('-created_at')


class PaymentDetailView(generics.RetrieveAPIView):
    """GET /payments/:id/ — detalle de un pago."""
    serializer_class = PaymentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Payment.objects.filter(booking__user=self.request.user)


class PaymentInitView(APIView):
    """
    POST /payments/init/
    Crea la orden en Flow y devuelve la URL de pago para redirigir al usuario.
    """
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentInitSerializer(
            data=request.data, context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        booking = serializer.context['booking']

        # Crear o recuperar el Payment pendiente
        payment, created = Payment.objects.get_or_create(
            booking=booking,
            defaults={
                'provider': serializer.validated_data['provider'],
                'amount': booking.event.price_clp,
                'currency': 'CLP',
                'status': 'pending',
            }
        )

        if payment.status == 'paid':
            return Response({'detail': 'Ya fue pagado.'}, status=400)

        # FIX: si el pago anterior falló, resetear a 'pending' para el reintento.
        # Sin esto, el polling devolvería 'failed' inmediatamente para la nueva orden.
        if not created and payment.status == 'failed':
            payment.status = 'pending'
            payment.save(update_fields=['status'])

        frontend_url = getattr(settings, 'FRONTEND_URL', 'mqma://payment/return')
        backend_url = getattr(settings, 'BACKEND_URL', 'http://localhost:8000')
        try:
            result = create_payment_order(
                booking_id=str(booking.id),
                amount=payment.amount,
                email=request.user.email,
                subject=f'MQMA — Mesa {booking.event.event_date}',
                return_url=frontend_url,                                          # Deep-link de la app
                notify_url=f'{backend_url}/api/v1/payments/webhook/flow/',        # Webhook server-to-server
            )
        except Exception as e:
            return Response({'detail': f'Error al crear orden: {str(e)}'}, status=502)

        payment.provider_id = result['token']
        payment.raw_response = result
        payment.save(update_fields=['provider_id', 'raw_response'])

        return Response({
            'payment_id': str(payment.id),
            'payment_url': result['payment_url'],
            'token': result['token'],
        })


class FlowWebhookView(APIView):
    """
    POST /payments/webhook/flow/
    Endpoint que Flow llama para confirmar el pago.
    No requiere autenticación — verifica firma HMAC.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        data = dict(request.data)
        # Flow envía los valores como listas en algunos casos
        data = {k: v[0] if isinstance(v, list) else v for k, v in data.items()}

        if not verify_webhook_signature(dict(data)):
            return Response({'detail': 'Firma inválida.'}, status=400)

        token = data.get('token')
        if not token:
            return Response({'detail': 'Token requerido.'}, status=400)

        try:
            flow_status = get_payment_status(token)
        except Exception:
            return Response({'detail': 'Error consultando Flow.'}, status=502)

        # flow status 2 = pagado, 3 = rechazado, 4 = anulado
        payment = Payment.objects.filter(provider_id=token).first()
        if not payment:
            return Response({'detail': 'Pago no encontrado.'}, status=404)

        _apply_flow_status(payment, flow_status)
        return Response({'detail': 'OK'})


def _apply_flow_status(payment: Payment, flow_status: dict) -> None:
    """Aplica el código de estado de Flow al Payment (y su Booking si corresponde)."""
    flow_code = int(flow_status.get('status', 0))
    if flow_code == 2 and payment.status != 'paid':
        payment.status = 'paid'
        payment.paid_at = timezone.now()
        payment.booking.status = 'confirmed'
        payment.booking.save(update_fields=['status'])
    elif flow_code in (3, 4):
        payment.status = 'failed'

    payment.raw_response = flow_status
    payment.save(update_fields=['status', 'paid_at', 'raw_response'])


class PaymentStatusView(APIView):
    """
    GET /payments/status/?token=<flow_token>
    El app consulta el estado después de que el usuario regresa del pago.

    Si el pago sigue en 'pending', consulta Flow directamente como fallback
    (evita dependencia del webhook para el cliente — útil en dev sin ngrok).
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        token = request.query_params.get('token')
        if not token:
            return Response({'detail': 'Token requerido.'}, status=400)

        payment = Payment.objects.filter(
            provider_id=token,
            booking__user=request.user,
        ).select_related('booking').first()

        if not payment:
            return Response({'detail': 'No encontrado.'}, status=404)

        # Fallback: si está pendiente, preguntarle directamente a Flow.
        # Esto permite confirmar pagos aunque el webhook no haya llegado
        # (ej. desarrollo local sin ngrok, o webhook que llegó tarde).
        if payment.status == 'pending':
            try:
                flow_data = get_payment_status(token)
                _apply_flow_status(payment, flow_data)
                payment.refresh_from_db(fields=['status', 'paid_at'])
            except Exception:
                pass  # Usar el status cacheado si Flow no responde

        return Response({
            'status': payment.status,
            'booking_status': payment.booking.status,
            'paid_at': payment.paid_at,
        })
