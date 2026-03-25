
from rest_framework import serializers
from .models import User, Profile, ProfileTag


class ProfileTagSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfileTag
        fields = ['id', 'tag', 'category']


class ProfileSerializer(serializers.ModelSerializer):
    tags = ProfileTagSerializer(many=True, read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = Profile
        fields = [
            'id', 'email', 'name', 'age', 'bio', 'photo',
            'industry', 'stage', 'looking_for', 'linkedin_url',
            'mbti', 'city', 'nps_avg', 'onboarding_complete',
            'tags', 'created_at',
        ]
        read_only_fields = ['id', 'nps_avg', 'created_at']


class ProfileUpdateSerializer(serializers.ModelSerializer):
    tags = ProfileTagSerializer(many=True, required=False)

    class Meta:
        model = Profile
        fields = [
            'name', 'age', 'bio', 'photo', 'industry',
            'stage', 'looking_for', 'linkedin_url', 'mbti',
            'city', 'onboarding_complete', 'tags',
        ]

    def update(self, instance, validated_data):
        tags_data = validated_data.pop('tags', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if tags_data is not None:
            instance.tags.all().delete()
            for tag in tags_data:
                ProfileTag.objects.create(profile=instance, **tag)
        return instance


class UserMeSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'email', 'phone', 'is_verified', 'created_at', 'profile']
        read_only_fields = ['id', 'email', 'is_verified', 'created_at']
