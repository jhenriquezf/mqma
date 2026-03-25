import uuid
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.db import models
from phonenumber_field.modelfields import PhoneNumberField


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email requerido")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    phone = PhoneNumberField(blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    class Meta:
        verbose_name = "usuario"
        verbose_name_plural = "usuarios"
        ordering = ["-created_at"]

    def __str__(self):
        return self.email


class Profile(models.Model):
    STAGE_CHOICES = [
        ("idea", "Idea"),
        ("mvp", "MVP"),
        ("early", "Early stage"),
        ("growth", "Growth"),
        ("scale", "Scale"),
        ("executive", "Ejecutivo / corporativo"),
        ("investor", "Inversor"),
        ("other", "Otro"),
    ]

    LOOKING_FOR_CHOICES = [
        ("cofounder", "Cofundador"),
        ("clients", "Clientes"),
        ("investors", "Inversores"),
        ("talent", "Talento"),
        ("mentors", "Mentores"),
        ("network", "Expandir red"),
        ("friends", "Amigos"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    name = models.CharField(max_length=120)
    age = models.PositiveSmallIntegerField(null=True, blank=True)
    bio = models.TextField(blank=True)
    photo = models.ImageField(upload_to="profiles/", blank=True)
    industry = models.CharField(max_length=80, blank=True)
    stage = models.CharField(max_length=20, choices=STAGE_CHOICES, blank=True)
    looking_for = models.CharField(max_length=20, choices=LOOKING_FOR_CHOICES, blank=True)
    linkedin_url = models.URLField(blank=True)
    mbti = models.CharField(max_length=4, blank=True)
    city = models.ForeignKey(
        "events.City", on_delete=models.SET_NULL, null=True, blank=True, related_name="profiles"
    )
    nps_avg = models.FloatField(default=0.0)
    onboarding_complete = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "perfil"
        verbose_name_plural = "perfiles"

    def __str__(self):
        return f"{self.name} ({self.user.email})"


class DeviceToken(models.Model):
    """FCM push token de un dispositivo del usuario."""

    PLATFORM_CHOICES = [
        ("android", "Android"),
        ("ios", "iOS"),
        ("web", "Web"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="device_tokens"
    )
    token = models.CharField(max_length=255)
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES, default="android")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("user", "token")
        verbose_name = "token de dispositivo"
        verbose_name_plural = "tokens de dispositivo"

    def __str__(self):
        return f"{self.user.email} — {self.platform} ({self.token[:20]}…)"


class ProfileTag(models.Model):
    CATEGORY_CHOICES = [
        ("interest", "Interés"),
        ("skill", "Habilidad"),
        ("sector", "Sector"),
        ("goal", "Objetivo"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(Profile, on_delete=models.CASCADE, related_name="tags")
    tag = models.CharField(max_length=50)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)

    class Meta:
        unique_together = ("profile", "tag")
        verbose_name = "tag de perfil"
        verbose_name_plural = "tags de perfil"

    def __str__(self):
        return f"{self.tag} ({self.category})"
