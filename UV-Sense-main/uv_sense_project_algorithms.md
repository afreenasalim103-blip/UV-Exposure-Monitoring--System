# UVORA: PROJECT OVERVIEW & CORE ALGORITHMS

## 1. Project Introduction
UV-Sense is an advanced, AI-driven personal health platform designed to mitigate the risks of UV exposure and promote skin health. By integrating real-time environmental data with individual skin profiles, the platform provides hyper-personalized sun protection recommendations and direct access to dermatological expertise.

## 2. Core Intelligent Modules
The platform is built on four primary pillars of intelligence:
- **Environmental Intelligence**: Real-time UV and weather tracking.
- **Computer Vision (CV)**: Automated skin analysis via Generative AI.
- **Predictive Recommendations**: Personalized safety advice and product matching.
- **Premium Ecosystem**: A tiered access model for specialized healthcare tools.

## 3. Technology Stack
- **Frontend**: Flutter (Cross-platform Android & iOS)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **AI Engine**: Google Gemini 2.5 Flash / Flash-Lite
- **External APIs**: OpenWeatherMap (Weather & OneCall UV Index)

---

## 4. Primary Algorithms

### A. Environmental Data Fusion Algorithm
This algorithm determines the user's localized risk factor based on real-time physics:
1.  **Location Acquisition**: Uses `Geolocator` to fetch high-precision GPS coordinates.
2.  **Reverse Geocoding**: Converts coordinates to city names via OpenWeather Geo-API for UI context.
3.  **Weather Fetching**: Concurrent API calls to OpenWeatherMap for current Temperature and specific UV Index.
4.  **Logging**: Automatically persists exposure data (`latitude`, `longitude`, `uv_index`) to `tbl_uv_log` to build a historical exposure profile for the user.

### B. AI Skin Type Analysis Algorithm (Computer Vision)
Located in `SkinScannerPage`, this module uses Generative AI to replace traditional rule-based classifiers:
1.  **Image Processing**: Captures/picks image and converts to `DataPart` (JPEG bytes).
2.  **Zero-Shot Analysis**: Sends the image to Gemini 2.5 with a strict dermatological prompt.
3.  **Logic**:
    - **Identify Fitzpatrick Scale**: Scale 1 (Fair) to 6 (Deep).
    - **Categorize Condition**: Detects texture, shine, and flakiness to determine if the skin is OILY, DRY, NORMAL, COMBINATION, or SENSITIVE.
4.  **Database Integration**: Updates the User's `skintype_id` based on the AI's standard JSON response.

### C. Personalized Protection Algorithm (SmartProtection)
Used in `UserHomePage` to generate advice based on current environmental conditions:
1.  **Input Vector**: `(UV_Index, SkinType, Location, Temperature)`.
2.  **Processing**: The Gemini 2.5 AI acts as an inference engine to determine:
    - **Optimal SPF**: Maps UV intensity to minimum required Sun Protection Factor.
    - **Textile Selection**: Recommends clothing colors and types (e.g., UV-resistant, long-sleeve) based on thermal and UV data.
    - **Safety Tips**: Generates 2-3 critical behavioral tips (e.g., "Seek shade between 12 PM - 3 PM").

### D. Product Recommendation Engine
Filters the product database based on multi-dimensional constraints:
1.  **Constraint 1 (UV Level)**: Maps numerical UV Index to categorical levels (Low, Moderate, High, Extreme).
2.  **Constraint 2 (Skin Compatibility)**: Queries `tbl_product` joined with `tbl_product_skintype`.
3.  **Matching Logic**: Using internal relational queries to match the current environmental threat (UV Level) and the internal susceptibility (User Skin Type).
4.  **Ranking**: Displays the most compatible protection products to the user's home screen.

---

## 5. Security & Access Control Algorithm
The newly implemented Subscription Access Logic:
1.  **Status Check**: Verifies if the user's current date is within the `start_date` and `end_date` of an 'active' entry in `tbl_user_subscription`.
2.  **Feature Gating**:
    - **Map Discovery**: High-bandwidth data locked to premium.
    - **Skin Scanner**: Advanced ML diagnostic tool locked to premium.
    - **Dermatologist View**: Exclusive direct-to-doctor access locked to premium.
3.  **Monetization Flow**: Integrated simulated Payment Gateway to update membership status in real-time.

## 6. Functional Summary Table
| Module | Primary Algorithm | AI / API |
| :--- | :--- | :--- |
| **Exposure Tracking** | GPS-Weather-Log Fusion | OpenWeather API |
| **Skin Diagnosis** | CV-based Fitzpatrick Scoring | Gemini 2.5 |
| **AI Assistant** | NLP context-aware prompting | Gemini 2.5 |
| **Marketplace** | Many-to-Many relational filtering | PostgreSQL RLS |
| **Subscriptions** | Date-based access control | Supabase |
