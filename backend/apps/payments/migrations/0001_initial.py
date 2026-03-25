import uuid
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    initial = True
    dependencies = [
        ('events', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Payment',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('provider', models.CharField(choices=[('flow','Flow'),('mercadopago','MercadoPago'),('manual','Manual')], default='flow', max_length=20)),
                ('provider_id', models.CharField(blank=True, help_text='ID externo del proveedor', max_length=120)),
                ('amount', models.PositiveIntegerField(help_text='Monto en moneda local (entero)')),
                ('currency', models.CharField(default='CLP', max_length=3)),
                ('status', models.CharField(choices=[('pending','Pendiente'),('paid','Pagado'),('failed','Fallido'),('refunded','Reembolsado')], default='pending', max_length=20)),
                ('paid_at', models.DateTimeField(blank=True, null=True)),
                ('raw_response', models.JSONField(blank=True, default=dict)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('booking', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='payment', to='events.booking')),
            ],
            options={'verbose_name': 'pago', 'verbose_name_plural': 'pagos', 'ordering': ['-created_at']},
        ),
    ]
