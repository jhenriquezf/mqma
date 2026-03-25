"""
Servicio FCM (Firebase Cloud Messaging) para notificaciones push.

Configuración en .env / settings.py:
    FIREBASE_CREDENTIALS = "/ruta/al/service-account.json"
    # Dejar vacío para deshabilitar FCM (útil en tests / dev sin Firebase)

Flujo:
    send_push(user, title=..., body=..., data={...})
     → obtiene tokens del modelo DeviceToken
     → envía mensajes via firebase-admin
     → elimina tokens stale (UnregisteredError)
"""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

from django.conf import settings

if TYPE_CHECKING:
    from apps.users.models import User

logger = logging.getLogger(__name__)

_app = None  # Firebase app singleton


def _get_app():
    """Lazy-initialize Firebase Admin SDK. Retorna None si no está configurado."""
    global _app

    if _app is not None:
        return _app

    cred_path: str = getattr(settings, "FIREBASE_CREDENTIALS", "") or ""
    if not cred_path:
        return None

    try:
        import firebase_admin
        from firebase_admin import credentials

        # Evitar doble inicialización (ej. Celery workers)
        if firebase_admin._apps:
            _app = firebase_admin.get_app()
        else:
            cred = credentials.Certificate(cred_path)
            _app = firebase_admin.initialize_app(cred)

        logger.info("[FCM] Firebase Admin SDK inicializado ✓")
        return _app

    except Exception as exc:
        logger.error("[FCM] Error al inicializar Firebase: %s", exc)
        return None


def send_push(
    user: "User",
    *,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> int:
    """
    Envía notificación push a todos los tokens registrados del usuario.

    - Si Firebase no está configurado: registra warning y retorna 0.
    - Tokens inválidos/expirados se eliminan automáticamente.
    - Retorna el número de envíos exitosos.
    """
    from firebase_admin import messaging
    from apps.users.models import DeviceToken

    app = _get_app()
    if app is None:
        logger.warning("[FCM] Sin Firebase — omitiendo push a %s", user.email)
        return 0

    tokens: list[str] = list(
        DeviceToken.objects.filter(user=user).values_list("token", flat=True)
    )
    if not tokens:
        logger.debug("[FCM] Sin tokens para %s", user.email)
        return 0

    sent = 0
    stale: list[str] = []

    for token in tokens:
        try:
            msg = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                # data solo acepta strings
                data={k: str(v) for k, v in (data or {}).items()},
                android=messaging.AndroidConfig(priority="high"),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default"),
                    ),
                ),
                token=token,
            )
            messaging.send(msg, app=app)
            sent += 1
            logger.info("[FCM] ✓ %s ← %s…", user.email, token[:16])

        except messaging.UnregisteredError:
            stale.append(token)

        except Exception as exc:
            logger.error("[FCM] Error → %s: %s", user.email, exc)

    if stale:
        DeviceToken.objects.filter(token__in=stale).delete()
        logger.info("[FCM] %d token(s) stale eliminados de %s", len(stale), user.email)

    return sent


def send_multicast(
    users: list["User"],
    *,
    title: str,
    body: str,
    data: dict[str, str] | None = None,
) -> int:
    """
    Envía la misma notificación a una lista de usuarios.
    Usa send_each_for_multicast para lotes de hasta 500 tokens.
    """
    from firebase_admin import messaging
    from apps.users.models import DeviceToken

    app = _get_app()
    if app is None:
        logger.warning("[FCM] Sin Firebase — omitiendo multicast a %d usuarios", len(users))
        return 0

    user_ids = [u.id for u in users]
    tokens: list[str] = list(
        DeviceToken.objects.filter(user_id__in=user_ids).values_list("token", flat=True)
    )
    if not tokens:
        return 0

    # FCM admite hasta 500 tokens por lote
    total_sent = 0
    stale: list[str] = []

    for i in range(0, len(tokens), 500):
        batch = tokens[i : i + 500]
        multicast = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(aps=messaging.Aps(sound="default")),
            ),
            tokens=batch,
        )
        result: messaging.BatchResponse = messaging.send_each_for_multicast(
            multicast, app=app
        )
        total_sent += result.success_count

        for idx, resp in enumerate(result.responses):
            if not resp.success:
                exc = resp.exception
                if isinstance(exc, messaging.UnregisteredError):
                    stale.append(batch[idx])
                elif exc:
                    logger.error("[FCM] Multicast error: %s", exc)

    if stale:
        DeviceToken.objects.filter(token__in=stale).delete()
        logger.info("[FCM] %d tokens stale eliminados (multicast)", len(stale))

    logger.info("[FCM] Multicast: %d/%d enviados", total_sent, len(tokens))
    return total_sent
