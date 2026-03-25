import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):
    """Fase 3: agrega FK event a MatchGroup (ciclo roto)."""

    dependencies = [
        ('matching', '0001_initial'),
        ('events', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='matchgroup',
            name='event',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='groups',
                to='events.event',
            ),
            preserve_default=False,
        ),
    ]
