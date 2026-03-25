import django.db.models.deletion
import uuid
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):
    """
    Fase 2: City, Restaurant, Event, Booking.
    Depende de users.0001 y matching.0001 (que aun no tiene FK a Event).
    """

    initial = True
    dependencies = [
        ('matching', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='City',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=80)),
                ('country', models.CharField(max_length=80)),
                ('timezone', models.CharField(default='America/Santiago', max_length=50)),
                ('active', models.BooleanField(default=False)),
                ('min_users', models.PositiveIntegerField(default=120)),
            ],
            options={'verbose_name': 'ciudad', 'verbose_name_plural': 'ciudades', 'ordering': ['country', 'name']},
        ),
        migrations.CreateModel(
            name='Restaurant',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('name', models.CharField(max_length=120)),
                ('address', models.CharField(max_length=200)),
                ('avg_price_clp', models.PositiveIntegerField(help_text='Precio promedio por persona en CLP')),
                ('dietary_options', models.JSONField(blank=True, default=list)),
                ('contact_name', models.CharField(blank=True, max_length=80)),
                ('contact_phone', models.CharField(blank=True, max_length=20)),
                ('active', models.BooleanField(default=True)),
                ('notes', models.TextField(blank=True)),
                ('city', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='restaurants', to='events.city')),
            ],
            options={'verbose_name': 'restaurante', 'verbose_name_plural': 'restaurantes'},
        ),
        migrations.CreateModel(
            name='Event',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('event_date', models.DateField()),
                ('event_time', models.TimeField()),
                ('capacity', models.PositiveIntegerField(default=30)),
                ('price_clp', models.PositiveIntegerField(default=14900)),
                ('status', models.CharField(choices=[('draft','Borrador'),('open','Abierto'),('matching','En matching'),('confirmed','Confirmado'),('done','Realizado'),('cancelled','Cancelado')], default='draft', max_length=20)),
                ('type', models.CharField(choices=[('dinner','Cena'),('lunch','Almuerzo'),('coffee','Café'),('drinks','Drinks'),('women_only','Solo mujeres'),('founders','Founders')], default='dinner', max_length=20)),
                ('notes', models.TextField(blank=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('city', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='events', to='events.city')),
                ('restaurant', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='events', to='events.restaurant')),
            ],
            options={'verbose_name': 'evento', 'verbose_name_plural': 'eventos', 'ordering': ['-event_date']},
        ),
        migrations.CreateModel(
            name='Booking',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('status', models.CharField(choices=[('pending','Pendiente pago'),('confirmed','Confirmado'),('cancelled','Cancelado'),('no_show','No se presentó'),('attended','Asistió')], default='pending', max_length=20)),
                ('checked_in', models.BooleanField(default=False)),
                ('checked_in_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('event', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='bookings', to='events.event')),
                ('group', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='bookings', to='matching.matchgroup')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='bookings', to=settings.AUTH_USER_MODEL)),
            ],
            options={'verbose_name': 'reserva', 'verbose_name_plural': 'reservas', 'unique_together': {('user', 'event')}},
        ),
    ]
