
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from unfold.admin import ModelAdmin, TabularInline
from .models import User, Profile, ProfileTag, DeviceToken


class ProfileTagInline(TabularInline):
    model = ProfileTag
    fields = ['tag', 'category']
    extra = 0


class ProfileInline(TabularInline):
    model = Profile
    fields = ['name', 'industry', 'stage', 'looking_for', 'nps_avg', 'onboarding_complete']
    readonly_fields = ['nps_avg']
    extra = 0
    max_num = 1


@admin.register(User)
class UserAdmin(ModelAdmin, BaseUserAdmin):
    list_display = ['email', 'is_verified', 'is_active', 'is_staff', 'created_at']
    list_filter = ['is_active', 'is_verified', 'is_staff']
    search_fields = ['email', 'phone']
    ordering = ['-created_at']
    inlines = [ProfileInline]
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Info', {'fields': ('phone', 'is_verified')}),
        ('Permisos', {'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
    )
    add_fieldsets = (
        (None, {'fields': ('email', 'password1', 'password2')}),
    )


@admin.register(DeviceToken)
class DeviceTokenAdmin(ModelAdmin):
    list_display = ['user', 'platform', 'short_token', 'created_at']
    list_filter = ['platform']
    search_fields = ['user__email', 'token']
    readonly_fields = ['created_at', 'updated_at']

    @admin.display(description='Token')
    def short_token(self, obj):
        return f"{obj.token[:24]}…"


@admin.register(Profile)
class ProfileAdmin(ModelAdmin):
    list_display = ['name', 'user', 'stage', 'looking_for', 'city', 'nps_avg', 'onboarding_complete']
    list_filter = ['stage', 'looking_for', 'city', 'onboarding_complete']
    search_fields = ['name', 'user__email', 'industry']
    inlines = [ProfileTagInline]
    readonly_fields = ['nps_avg', 'created_at']
