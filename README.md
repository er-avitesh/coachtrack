# CoachTrack MVP - Complete Setup Guide

## Project Structure

```
coachtrack/
├── ARCHITECTURE.md
├── database/
│   └── schema.sql               ← Run this to create all tables + seed data
├── backend/
│   ├── package.json
│   ├── .env.example             ← Copy to .env and fill in values
│   └── src/
│       ├── server.js            ← Express entry point
│       ├── db/
│       │   └── index.js         ← PostgreSQL pool
│       ├── middleware/
│       │   └── auth.js          ← JWT middleware
│       ├── controllers/
│       │   ├── authController.js
│       │   ├── profileController.js
│       │   ├── trackingController.js
│       │   ├── mealsController.js
│       │   ├── dietController.js
│       │   ├── workoutController.js
│       │   ├── tipsController.js
│       │   ├── photosController.js
│       │   └── coachController.js
│       └── routes/
│           ├── auth.js
│           ├── profile.js
│           ├── tracking.js
│           ├── meals.js
│           ├── diet.js
│           ├── workout.js
│           ├── tips.js
│           ├── photos.js
│           └── coach.js
└── mobile/
    ├── pubspec.yaml
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants.dart
        │   ├── theme.dart
        │   └── router.dart
        ├── models/
        │   └── models.dart
        ├── services/
        │   └── api_service.dart
        ├── providers/
        │   └── auth_provider.dart
        ├── widgets/
        │   └── app_widgets.dart
        └── screens/
            ├── auth/
            │   ├── login_screen.dart
            │   └── register_screen.dart
            ├── participant/
            │   ├── dashboard_screen.dart
            │   ├── tracking_screen.dart
            │   ├── meal_calculator_screen.dart
            │   ├── my_meals_screen.dart
            │   ├── workout_screen.dart
            │   ├── progress_screen.dart
            │   └── profile_screen.dart
            └── coach/
                ├── coach_dashboard_screen.dart
                ├── client_profile_screen.dart
                ├── assign_diet_screen.dart
                ├── assign_workout_screen.dart
                └── add_tips_screen.dart
```

---

## STEP-BY-STEP SETUP

### Prerequisites

- Node.js 18+
- Flutter 3.19+
- PostgreSQL (or Supabase free account)
- AWS account (for S3 photo storage) — optional for MVP
- Git

---

## STEP 1: Database Setup (Supabase — free & fastest)

1. Go to https://supabase.com → New project
2. Note your connection string (Settings → Database → Connection string → URI)
   It looks like: `postgresql://postgres:[password]@[host]:5432/postgres`
3. Open the SQL editor in Supabase dashboard
4. Copy and paste the entire contents of `database/schema.sql`
5. Click **Run** — this creates all tables AND seeds 30 exercises

**Alternative: Local PostgreSQL**
```bash
createdb coachtrack
psql coachtrack < database/schema.sql
```

---

## STEP 2: Backend Setup

```bash
cd backend
npm install
```

Create your `.env` file:
```bash
cp .env.example .env
```

Edit `.env`:
```env
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://postgres:yourpassword@yourhost:5432/postgres
JWT_SECRET=pick-a-long-random-string-here-change-me
JWT_EXPIRES_IN=7d

# S3 (optional - skip for MVP testing)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
AWS_S3_BUCKET=coachtrack-photos
```

Start the server:
```bash
npm run dev      # development (auto-reload)
# OR
npm start        # production
```

Test it:
```bash
curl http://localhost:3000/health
# Expected: {"status":"ok","timestamp":"..."}
```

---

## STEP 3: AWS S3 Setup (for photo uploads)

**Skip this for initial testing** — photo upload won't work but everything else will.

When ready:
1. Go to AWS Console → S3 → Create Bucket
2. Bucket name: `coachtrack-photos`
3. Region: pick closest to your users
4. Uncheck "Block all public access" → confirm
5. Add a bucket policy (Permissions tab):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::coachtrack-photos/*"
    }
  ]
}
```

6. Create IAM user with `AmazonS3FullAccess` policy
7. Generate access keys → paste into `.env`

---

## STEP 4: Flutter App Setup

```bash
cd mobile
flutter pub get
```

Update the API URL in `lib/core/constants.dart`:
```dart
// For local testing:
static const String baseUrl = 'http://10.0.2.2:3000/api';   // Android emulator
static const String baseUrl = 'http://localhost:3000/api';   // iOS simulator

// After deploying backend:
static const String baseUrl = 'https://your-api.railway.app/api';
```

Run on iOS simulator:
```bash
flutter run -d ios
```

Run on Android emulator:
```bash
flutter run -d android
```

Run on physical device:
- Connect device via USB
- Enable developer mode + USB debugging
```bash
flutter run
```

---

## STEP 5: Test the Full Flow

### Register a Coach
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "coach_sarah",
    "email": "sarah@gym.com",
    "password": "password123",
    "full_name": "Sarah Johnson",
    "role": "coach"
  }'
```

### Register a Participant
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@email.com",
    "password": "password123",
    "full_name": "John Doe",
    "role": "participant"
  }'
```

### Login (save the token)
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "coach_sarah", "password": "password123"}'
```

Copy the `token` from the response. Then use it:

### Coach: Add a client
```bash
curl -X POST http://localhost:3000/api/coach/clients/add \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"participant_username": "john_doe"}'
```

### Coach: Assign diet to client
```bash
curl -X POST http://localhost:3000/api/diet/assign \
  -H "Authorization: Bearer COACH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "participant_id": 2,
    "plan_name": "Weight Loss Plan",
    "meals": [
      {"meal_slot": "breakfast", "calories": 350, "protein_g": 30, "carbs_g": 35, "fat_g": 8},
      {"meal_slot": "lunch",     "calories": 500, "protein_g": 40, "carbs_g": 50, "fat_g": 12},
      {"meal_slot": "snack",     "calories": 150, "protein_g": 10, "carbs_g": 15, "fat_g": 4},
      {"meal_slot": "dinner",    "calories": 450, "protein_g": 40, "carbs_g": 40, "fat_g": 14}
    ]
  }'
```

### Participant: Add daily tracking
```bash
curl -X POST http://localhost:3000/api/tracking/add \
  -H "Authorization: Bearer PARTICIPANT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "weight_kg": 78.5,
    "stress_level": 4,
    "water_intake_liters": 2.5,
    "steps": 8500,
    "sleep_hours": 7.5,
    "mood": "Good"
  }'
```

### Participant: Create a meal
```bash
curl -X POST http://localhost:3000/api/meals/create \
  -H "Authorization: Bearer PARTICIPANT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "meal_name": "Paneer Poha",
    "calories_per_100g": 180,
    "protein_per_100g": 12,
    "carbs_per_100g": 20,
    "fat_per_100g": 8
  }'
```

### Participant: Calculate meal quantity
```bash
curl -X POST http://localhost:3000/api/meals/calculate \
  -H "Authorization: Bearer PARTICIPANT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"meal_id": 1, "target_calories": 350}'

# Response:
# {"success": true, "meal_name": "Paneer Poha",
#  "nutrition": {"grams_needed": 194, "calories": 350,
#                "protein_g": 23.3, "carbs_g": 38.8, "fat_g": 15.5}}
```

---

## STEP 6: Deploy the Backend

### Option A: Railway (Recommended — free tier, 5 min setup)

1. Push your backend code to GitHub
2. Go to https://railway.app → New Project → Deploy from GitHub
3. Select your repo, set root directory to `/backend`
4. Add environment variables (copy from `.env`)
5. Railway auto-detects Node.js and deploys
6. Copy your Railway URL (e.g. `https://coachtrack-api.up.railway.app`)

### Option B: Render (also free)

1. Push backend to GitHub
2. Go to https://render.com → New Web Service
3. Connect repo, set Build Command: `npm install`, Start Command: `npm start`
4. Add environment variables
5. Deploy

### After Deploying Backend:

Update `lib/core/constants.dart` in Flutter:
```dart
static const String baseUrl = 'https://your-api.railway.app/api';
```

---

## STEP 7: Build Flutter for Distribution

### iOS
```bash
# Requires a Mac with Xcode
flutter build ios --release
# Open ios/Runner.xcworkspace in Xcode
# Archive → Distribute App
```

### Android
```bash
flutter build apk --release
# APK is at: build/app/outputs/flutter-apk/app-release.apk
# Share directly or upload to Play Store
```

---

## API Reference Summary

| Method | Endpoint                        | Auth    | Description                    |
|--------|---------------------------------|---------|--------------------------------|
| POST   | /auth/register                  | None    | Register user                  |
| POST   | /auth/login                     | None    | Login, returns JWT             |
| GET    | /auth/me                        | Any     | Get current user               |
| POST   | /profile/create                 | Any     | Create/update intake profile   |
| GET    | /profile/get                    | Any     | Get profile (coach: ?user_id)  |
| POST   | /tracking/add                   | Part.   | Add/update daily tracking      |
| GET    | /tracking/get                   | Any     | Get tracking history           |
| GET    | /tracking/today                 | Part.   | Get today's entry              |
| POST   | /meals/create                   | Part.   | Create custom meal             |
| GET    | /meals/list                     | Part.   | List my meals                  |
| DELETE | /meals/:id                      | Part.   | Delete a meal                  |
| POST   | /meals/calculate                | Part.   | Calculate grams for calories   |
| POST   | /diet/assign                    | Coach   | Assign macro plan to client    |
| GET    | /diet/get                       | Any     | Get active diet plan           |
| GET    | /workout/exercises              | Any     | List exercise library          |
| POST   | /workout/assign                 | Coach   | Assign workout to client       |
| GET    | /workout/get                    | Any     | Get active workout plan        |
| POST   | /tips/add                       | Coach   | Add tip for client             |
| GET    | /tips/get                       | Any     | Get tips                       |
| GET    | /photos/upload-url              | Any     | Get S3 presigned upload URL    |
| POST   | /photos/confirm                 | Any     | Save photo record after upload |
| GET    | /photos/list                    | Any     | List body photos               |
| GET    | /coach/clients                  | Coach   | List all clients               |
| POST   | /coach/clients/add              | Coach   | Add client by username         |
| GET    | /coach/client/:id/summary       | Coach   | Full client summary            |

---

## Common Issues & Fixes

**CORS error from Flutter:**
The backend already has CORS enabled for all origins. If you still get errors, check the `baseUrl` in constants.dart matches your server exactly.

**Flutter can't connect to localhost:**
- iOS Simulator: use `http://localhost:3000/api` ✅
- Android Emulator: use `http://10.0.2.2:3000/api` ✅
- Physical device: use your computer's local IP, e.g. `http://192.168.1.5:3000/api`
- Also add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```

**Database connection fails:**
Check that `DATABASE_URL` in `.env` is correct. If using Supabase, ensure SSL is enabled (the backend sets `ssl: { rejectUnauthorized: false }` in production automatically).

**JWT token expired:**
Tokens expire in 7 days. User needs to log in again. The app handles this by redirecting to login when 401 is received.

**Photo upload not working:**
Skip S3 setup for MVP testing — all other features work without it. When ready, ensure bucket region matches `AWS_REGION` in env.

---

## Cost Estimate (Monthly)

| Service       | Free Tier                | Paid Estimate       |
|---------------|--------------------------|---------------------|
| Railway       | $5 free credits/month    | ~$5-10/month        |
| Supabase      | 500MB DB free            | $25/month (8GB)     |
| AWS S3        | 5GB free first year      | ~$0.023/GB/month    |
| **Total MVP** | **$0** (free tiers)      | **~$30-40/month**   |

Free tiers are more than enough for an MVP with up to ~50 active users.
