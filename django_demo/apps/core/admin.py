from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from django_demo.apps.core.models import User

admin.site.register(User, UserAdmin)
