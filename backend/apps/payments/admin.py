
from django.contrib import admin
from unfold.admin import ModelAdmin
from .models import Payment


@admin.register(Payment)
class PaymentAdmin(ModelAdmin):
    list_display = ['booking', 'provider', 'amount', 'currency', 'status', 'paid_at']
    list_filter = ['status', 'provider', 'currency']
    search_fields = ['booking__user__email', 'provider_id']
    readonly_fields = ['raw_response', 'created_at', 'updated_at']
