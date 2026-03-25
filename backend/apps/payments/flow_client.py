
"""
Cliente Flow Chile — https://www.flow.cl/docs/api.html
Implementación de los endpoints necesarios: crear orden, confirmar webhook.
"""
import hashlib
import hmac
import urllib.parse
from django.conf import settings
import requests

FLOW_API_URL = getattr(settings, 'FLOW_API_URL', 'https://sandbox.flow.cl/api')
FLOW_API_KEY = getattr(settings, 'FLOW_API_KEY', '')
FLOW_SECRET_KEY = getattr(settings, 'FLOW_SECRET_KEY', '')


def _sign(params: dict) -> str:
    """Firma HMAC-SHA256 requerida por Flow."""
    sorted_params = sorted(params.items())
    to_sign = ''.join(f'{k}{v}' for k, v in sorted_params)
    return hmac.new(
        FLOW_SECRET_KEY.encode(),
        to_sign.encode(),
        hashlib.sha256
    ).hexdigest()


def create_payment_order(
    booking_id: str,
    amount: int,
    email: str,
    subject: str,
    return_url: str,
    notify_url: str,
) -> dict:
    """
    Crea una orden de pago en Flow.
    Retorna {'url': ..., 'token': ..., 'flowOrder': ...}
    """
    params = {
        'apiKey': FLOW_API_KEY,
        'amount': amount,
        'commerceOrder': str(booking_id)[:20],
        'currency': 'CLP',
        'email': email,
        'subject': subject,
        'urlConfirmation': notify_url,
        'urlReturn': return_url,
    }
    params['s'] = _sign(params)
    response = requests.post(
        f'{FLOW_API_URL}/payment/create',
        data=params,
        timeout=15,
    )
    response.raise_for_status()
    data = response.json()
    return {
        'payment_url': f"{data['url']}?token={data['token']}",
        'token': data['token'],
        'flow_order': data.get('flowOrder'),
    }


def get_payment_status(token: str) -> dict:
    """Consulta el estado de un pago por token."""
    params = {'apiKey': FLOW_API_KEY, 'token': token}
    params['s'] = _sign(params)
    response = requests.get(
        f'{FLOW_API_URL}/payment/getStatus',
        params=params,
        timeout=15,
    )
    response.raise_for_status()
    return response.json()


def verify_webhook_signature(data: dict) -> bool:
    """Verifica que el webhook viene de Flow."""
    received_sig = data.pop('s', None)
    if not received_sig:
        return False
    expected = _sign(data)
    return hmac.compare_digest(received_sig, expected)
