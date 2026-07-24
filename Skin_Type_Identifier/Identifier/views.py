from django.shortcuts import render
from django.conf import settings
import os


import numpy as np
import pandas as pd
from PIL import Image
import tensorflow as tf
from tensorflow.keras.preprocessing.image import load_img, img_to_array
import uuid
from tensorflow.keras.applications.mobilenet_v2 import preprocess_input
from urllib.parse import quote_plus

# Custom DepthwiseConv2D to handle Keras 2 -> Keras 3 groups parameter compatibility
class CustomDepthwiseConv2D(tf.keras.layers.DepthwiseConv2D):
    def __init__(self, **kwargs):
        kwargs.pop('groups', None)
        super().__init__(**kwargs)

# Load model ONCE (important for performance)
MODEL_PATH = os.path.join(settings.BASE_DIR, 'Assets', 'Model', 'BestModel.h5')
model = tf.keras.models.load_model(
    MODEL_PATH,
    custom_objects={'DepthwiseConv2D': CustomDepthwiseConv2D}
)

print(f"Loading model from: {os.path.abspath(MODEL_PATH)}")

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

# Class labels
CLASS_NAMES = ['acne', 'dry', 'oil']
def Prediction(request):
    context = {}

    if request.method == "POST" and request.FILES.get('image'):
        uploaded_file = request.FILES['image']

        # ✅ Create folder if not exists
        upload_dir = os.path.join(settings.MEDIA_ROOT, "TempImages")
        os.makedirs(upload_dir, exist_ok=True)

        # ✅ Avoid duplicate filenames
        filename = f"{uuid.uuid4()}_{uploaded_file.name}"

        file_path = os.path.join(upload_dir, filename)

        # ✅ Save file
        with open(file_path, 'wb+') as destination:
            for chunk in uploaded_file.chunks():
                destination.write(chunk)

        # ---- IMAGE PREPROCESSING ----
        img = load_img(file_path, target_size=(224, 224))
        img_array = img_to_array(img)
        img_array = preprocess_input(img_array.reshape(1, 224, 224, 3))

        # ---- PREDICTION ----
        predictions = model.predict(img_array)
        predicted_class_index = np.argmax(predictions)
        predicted_class = CLASS_NAMES[predicted_class_index]

        # ---- LOAD CSV ----
        csv_path = os.path.join(settings.BASE_DIR, 'Assets', 'Recommendations', 'recommendations.csv')
        recommendations_df = pd.read_csv(csv_path)

        # ---- FILTER ----
        filtered = recommendations_df[
            recommendations_df['Skin Type'].str.lower() == predicted_class.lower()
        ]

        recommendations = filtered.to_dict(orient='records')

        for rec in recommendations:
            rec['buy_link'] = generate_search_url(rec['Website'], rec['Product'])

        # ✅ Correct image URL
        image_url = f"{settings.MEDIA_URL}TempImages/{filename}"

        context = {
            'predicted_class': predicted_class,
            'recommendations': recommendations,
            'image_url': image_url
        }

    return render(request, 'SkinTypeIdentifier.html', context)

def generate_search_url(website, product):
    product_query = quote_plus(product)  # ✅ FIX

    if website.lower() == "amazon":
        return f"https://www.amazon.in/s?k={product_query}"

    elif website.lower() == "walmart":
        return f"https://www.walmart.com/search?q={product_query}"

    elif website.lower() == "ulta":
        return f"https://www.ulta.com/search?search={product_query}"

    elif website.lower() == "sephora":
        return f"https://www.sephora.com/search?keyword={product_query}"

    elif website.lower() == "target":
        return f"https://www.target.com/s?searchTerm={product_query}"

    elif website.lower() == "dermstore":
        return f"https://www.dermstore.com/search?searchTerm={product_query}"

    elif website.lower() == "paula's choice":
        return f"https://www.paulaschoice.com/search?q={product_query}"

    elif website.lower() == "deciem":
        return f"https://theordinary.com/en-in/search?q={product_query}"

    elif website.lower() == "cvs":
        return f"https://www.cvs.com/search?searchTerm={product_query}"

    elif website.lower() == "walgreens":
        return f"https://www.walgreens.com/search/results.jsp?Ntt={product_query}"

    else:
        return "#"

@csrf_exempt
def PredictionAPI(request):
    if request.method == "POST" and request.FILES.get('image'):
        try:
            uploaded_file = request.FILES['image']
            
            # Create folder if not exists
            upload_dir = os.path.join(settings.MEDIA_ROOT, "TempImages")
            os.makedirs(upload_dir, exist_ok=True)
            
            filename = f"{uuid.uuid4()}_{uploaded_file.name}"
            file_path = os.path.join(upload_dir, filename)
            
            with open(file_path, 'wb+') as destination:
                for chunk in uploaded_file.chunks():
                    destination.write(chunk)
            
            # Preprocess
            img = load_img(file_path, target_size=(224, 224))
            img_array = img_to_array(img)
            img_array = preprocess_input(img_array.reshape(1, 224, 224, 3))
            
            # Prediction
            predictions = model.predict(img_array)
            predicted_class_index = np.argmax(predictions)
            predicted_class = CLASS_NAMES[predicted_class_index]
            
            # Map Django classes to Flutter expected categories
            category_mapping = {
                'acne': 'SENSITIVE',  # or acne if tbl_skintype supports it. We use SENSITIVE based on previous prompt options.
                'dry': 'DRY',
                'oil': 'OILY'
            }
            category = category_mapping.get(predicted_class, 'NORMAL')

            return JsonResponse({
                "status": "success",
                "category": category,
                "original_prediction": predicted_class,
                "name": f"Skin Type: {category}",
                "description": f"Model identified skin condition as {predicted_class}."
            })
        except Exception as e:
            return JsonResponse({"status": "error", "message": str(e)}, status=500)
    
    return JsonResponse({"status": "error", "message": "Invalid request or missing image"}, status=400)