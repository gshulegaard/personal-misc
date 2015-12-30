# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations


class Migration(migrations.Migration):

    dependencies = [
        ('flipbook', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='base',
            name='intro',
            field=models.TextField(default=b''),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='base',
            name='meta_description',
            field=models.CharField(default=b'', max_length=150),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='base',
            name='og_article_tag',
            field=models.TextField(default=b''),
            preserve_default=True,
        ),
        migrations.AddField(
            model_name='base',
            name='title',
            field=models.TextField(default=b''),
            preserve_default=True,
        ),
    ]
