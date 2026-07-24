from django.urls import path
from . import views

urlpatterns = [
    path('', views.Prediction, name='prediction'),
    path('api/predict/', views.PredictionAPI, name='prediction_api'),
]