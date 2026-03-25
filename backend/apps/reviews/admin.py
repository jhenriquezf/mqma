
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Review


@admin.register(Review)
class ReviewAdmin(ModelAdmin):
    list_display = ['user', 'event', 'nps_score', 'group_rating', 'would_return', 'created_at']
    list_filter = ['would_return', 'event__city']
    search_fields = ['user__email', 'comment']
    readonly_fields = ['created_at']
