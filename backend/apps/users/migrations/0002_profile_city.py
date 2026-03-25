import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    """Fase 3: agrega FK city a Profile (ciclo roto)."""

    dependencies = [
        ('users', '0001_initial'),
        ('events', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='profile',
            name='city',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='profiles',
                to='events.city',
            ),
        ),
    ]
