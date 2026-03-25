import uuid
from django.db import migrations, models


class Migration(migrations.Migration):
    """
    Fase 1: MatchGroup sin FK a Event (se agrega en 0002 para romper ciclo con events).
    """

    initial = True
    dependencies = []

    operations = [
        migrations.CreateModel(
            name='MatchGroup',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('score', models.FloatField(default=0.0, help_text='Score calculado por el engine')),
                ('status', models.CharField(
                    choices=[
                        ('proposed', 'Propuesto por algoritmo'),
                        ('approved', 'Aprobado por admin'),
                        ('notified', 'Notificado a usuarios'),
                        ('done', 'Completado'),
                    ],
                    default='proposed',
                    max_length=20,
                )),
                ('admin_approved', models.BooleanField(default=False)),
                ('admin_notes', models.TextField(blank=True)),
                ('table_number', models.PositiveSmallIntegerField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'grupo',
                'verbose_name_plural': 'grupos',
                'ordering': ['-score'],
            },
        ),
    ]
