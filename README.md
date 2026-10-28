# WorkConnect

WorkConnect is a mobile-first marketplace that connects skilled workers with employers. The platform combines job discovery and applications with employer tools, real-time messaging, Firebase-backed data, and an AI-assisted worker matching API.

## Project components

| Component | Location | Purpose |
| --- | --- | --- |
| Flutter app | [`flutter_app/`](./flutter_app/) | Worker and employer mobile experiences; can also run in a browser |
| Admin dashboard | [`admin_app/`](./admin_app/) | React web dashboard built with Vite |
| API backend | [`backend_app/`](./backend_app/) | FastAPI services, including AI matching |
| Cloud Functions | [`functions/`](./functions/) | Firebase Cloud Functions |
| Firebase configuration | Repository root and `flutter_app/` | Firestore indexes and rules, storage rules, and app configuration |

## Features

- Worker and employer account workflows, profiles, and role switching
- Job posting, browsing, and applications
- Real-time messaging backed by Cloud Firestore
- AI-assisted candidate matching through the FastAPI backend
- Worker time logging and location-based features
- Digital offers, contract acceptance, and payment status tracking
- Administration tools for managing platform activity

For further design and functionality details, see [`DESIGN_DOC.md`](./DESIGN_DOC.md) and [`PROJECT_FUNCTIONALITY.md`](./PROJECT_FUNCTIONALITY.md).

## Requirements

Install the tools needed for the components you plan to run:

- Python 3 and `pip`
- Node.js and npm
- Flutter SDK and the Dart SDK bundled with Flutter
- A Firebase project configured for the app
- An OpenRouter API key for backend AI features

The Flutter app declares a Dart SDK constraint of `^3.9.2`. The Cloud Functions package specifies Node.js 18.

## Configuration and credentials

This repository intentionally excludes private credentials. Configure your own Firebase project and provide credentials locally; never commit service-account keys, `.env` files, passwords, or other secrets.

### Backend

1. Create a Firebase Admin service-account key for your Firebase project.
2. Save it locally as `backend_app/api/workconnectfirebasekey.json`. This path is expected by `backend_app/main.py` and is ignored by Git.
3. Create `backend_app/.env` and set your OpenRouter key:

   ```dotenv
   OPENROUTER_API_KEY=your_openrouter_api_key
   ```

4. If you use either admin-account helper, set `ADMIN_EMAIL` and `ADMIN_PASSWORD` in your shell. The root helper also requires `FIREBASE_API_KEY`; `backend_app/create_admin.py` requires `GOOGLE_APPLICATION_CREDENTIALS` (the path to your Firebase Admin service-account JSON). Optionally set `ADMIN_DISPLAY_NAME` for the backend helper.

### Firebase client apps

Set up Firebase for the platforms you intend to run. Use your own project configuration in the Flutter Firebase files (including the Android `google-services.json`) and the admin dashboard's Firebase configuration in `admin_app/src/firebase.js`. The repository includes platform configuration files, but you should verify they match your Firebase project before using the app.

## Run locally

### Backend API

From the repository root:

```powershell
cd backend_app
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
python main.py
```

The API listens on `http://localhost:8000`. Its root endpoint is `http://localhost:8000/`.

On macOS or Linux, activate the environment with `source venv/bin/activate` instead.

### Admin dashboard

In another terminal:

```powershell
cd admin_app
npm install
npm run dev
```

Vite prints the local URL when the development server starts. To create a production build, run `npm run build`.

### Flutter app

In another terminal:

```powershell
cd flutter_app
flutter pub get
flutter run
```

To run in Chrome, use `flutter run -d chrome`. A device or simulator must be installed and available for other targets.

### Start all components (Windows)

After configuring credentials and Firebase, run this from the repository root:

```bat
setup_and_start.bat
```

The script installs dependencies and launches the backend, admin dashboard, and Flutter app in separate terminal windows. To launch without the setup step, run `start_all.bat` after dependencies are installed. The scripts start Flutter in Chrome by default.

## Cloud Functions and Firebase rules

Install the Cloud Functions dependencies and use the Firebase CLI to serve or deploy functions:

```powershell
cd functions
npm install
npm run serve
```

Deploy functions with `npm run deploy` from `functions/`. Review the Firebase project selected by the Firebase CLI before deploying. Firestore and Storage rules and Firestore indexes are maintained in the repository root; review and deploy them to your own project as appropriate.

## Development checks

Run the admin dashboard linter and production build from `admin_app/`:

```powershell
npm run lint
npm run build
```

Run Flutter static analysis from `flutter_app/`:

```powershell
flutter analyze
```

## Security

- Do not commit Firebase service-account JSON files, `.env` files, API keys intended to remain private, or account passwords.
- The backend service-account path and local upload directory are excluded by the root `.gitignore`.
- Rotate any credential that has been exposed, and restrict Firebase API keys and service-account permissions in Google Cloud/Firebase.
- Review Firebase Security Rules before deploying; the client app must not rely on permissive rules for access control.
