import os
from pathlib import Path
import environ
import sentry_sdk

BASE_DIR = Path(__file__).resolve().parent.parent

SITE_ID = 1

env = environ.Env(DEBUG=(bool, False))
environ.Env.read_env(BASE_DIR / ".env")

SECRET_KEY = env("SECRET_KEY")
DEBUG = env("DEBUG")
ALLOWED_HOSTS = env.list("ALLOWED_HOSTS", default=["localhost", "127.0.0.1"])

DJANGO_APPS = [
    "unfold",
    "unfold.contrib.filters",
    "unfold.contrib.forms",
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.gis",
]

THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework.authtoken",
    "rest_framework_simplejwt",
    "corsheaders",
    "django_filters",
    "django_celery_beat",
    "django_celery_results",
    "storages",
    "phonenumber_field",
    "allauth",
    "allauth.account",
    "allauth.socialaccount", 
    "dj_rest_auth",
    "dj_rest_auth.registration",
]

LOCAL_APPS = [
    "apps.users",
    "apps.events",
    "apps.matching",
    "apps.payments",
    "apps.reviews",
]

INSTALLED_APPS = DJANGO_APPS + [
    "django.contrib.sites",
] + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "allauth.account.middleware.AccountMiddleware",
]

ROOT_URLCONF = "mqma.urls"
WSGI_APPLICATION = "mqma.wsgi.application"
AUTH_USER_MODEL = "users.User"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

DATABASES = {
    "default": env.db("DATABASE_URL", default="postgis://mqma:mqma@db:5432/mqma")
}

CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": env("REDIS_URL", default="redis://redis:6379/1"),
    }
}

# --- DRF ---
REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
        "rest_framework.authentication.SessionAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_FILTER_BACKENDS": ["django_filters.rest_framework.DjangoFilterBackend"],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
}

from datetime import timedelta
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(hours=12),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=30),
    "ROTATE_REFRESH_TOKENS": True,
}

# --- Celery ---
CELERY_BROKER_URL = env("REDIS_URL", default="redis://redis:6379/0")
CELERY_RESULT_BACKEND = "django-db"
CELERY_BEAT_SCHEDULER = "django_celery_beat.schedulers:DatabaseScheduler"
CELERY_TIMEZONE = "America/Santiago"

# --- CORS ---
CORS_ALLOWED_ORIGINS = env.list("CORS_ALLOWED_ORIGINS", default=["http://localhost:3000"])
CORS_ALLOW_CREDENTIALS = True

# --- Storage (GCS) ---
if env("USE_GCS", default=False):
    DEFAULT_FILE_STORAGE = "storages.backends.gcloud.GoogleCloudStorage"
    GS_BUCKET_NAME = env("GS_BUCKET_NAME")
    GS_DEFAULT_ACL = "publicRead"

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

# --- Unfold admin ---
UNFOLD = {
    "SITE_TITLE": "MQMA Admin",
    "SITE_HEADER": "Mesa que más aplaude",
    "SITE_SYMBOL": "restaurant",
    "THEME": "dark",
    "SIDEBAR": {
        "show_search": True,
        "show_all_applications": False,
        "navigation": [
            {
                "title": "Operaciones",
                "items": [
                    {"title": "Eventos", "icon": "event", "link": "/admin/events/event/"},
                    {"title": "Panel Matching", "icon": "auto_awesome", "link": "/admin/matching/panel/"},
                    {"title": "Grupos", "icon": "groups", "link": "/admin/matching/matchgroup/"},
                    {"title": "Reservas", "icon": "bookmark", "link": "/admin/events/booking/"},
                ],
            },
            {
                "title": "Usuarios",
                "items": [
                    {"title": "Usuarios", "icon": "person", "link": "/admin/users/user/"},
                    {"title": "Perfiles", "icon": "badge", "link": "/admin/users/profile/"},
                ],
            },
            {
                "title": "Finanzas",
                "items": [
                    {"title": "Pagos", "icon": "payments", "link": "/admin/payments/payment/"},
                ],
            },
            {
                "title": "Sistema",
                "items": [
                    {"title": "Tareas", "icon": "schedule", "link": "/admin/django_celery_beat/periodictask/"},
                ],
            },
        ],
    },
}

# --- Sentry ---
if not DEBUG:
    sentry_sdk.init(dsn=env("SENTRY_DSN", default=""), traces_sample_rate=0.2)

# --- Misc ---
LANGUAGE_CODE = "es-cl"
TIME_ZONE = "America/Santiago"
USE_I18N = True
USE_TZ = True
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
PHONENUMBER_DEFAULT_REGION = "CL"
# --- Allauth: login por email sin username ---
ACCOUNT_USER_MODEL_USERNAME_FIELD = None
ACCOUNT_USERNAME_REQUIRED = False
ACCOUNT_EMAIL_REQUIRED = True
ACCOUNT_AUTHENTICATION_METHOD = "email"
ACCOUNT_EMAIL_VERIFICATION = "none"


# --- Firebase / FCM ---
# Ruta al archivo JSON de credenciales de la cuenta de servicio Firebase.
# Descargar desde: Firebase Console → Project Settings → Service Accounts
# Dejar vacío para deshabilitar FCM (dev sin Firebase).
FIREBASE_CREDENTIALS = env("FIREBASE_CREDENTIALS", default="")

# --- Flow Chile ---
FLOW_API_URL = env("FLOW_API_URL", default="https://sandbox.flow.cl/api")
FLOW_API_KEY = env("FLOW_API_KEY", default="")
FLOW_SECRET_KEY = env("FLOW_SECRET_KEY", default="")

# --- URLs para pagos ---
# FRONTEND_URL: donde Flow redirige al usuario tras el pago.
# En producción móvil usar el deep-link de la app: mqma://payment/return
FRONTEND_URL = env("FRONTEND_URL", default="mqma://payment/return")

# BACKEND_URL: URL pública del servidor Django, usada para el webhook de Flow.
# En desarrollo local usar ngrok o similar.
BACKEND_URL = env("BACKEND_URL", default="http://localhost:8000")
