# GoalAchiever: Cross-Platform Goal Management App

## Overview
GoalAchiever is a cross-platform, mobile-first goal management app for students, built with a Flutter frontend and a FastAPI backend. It helps users break down long-term goals into actionable daily tasks, track progress, and leverage AI for smart planning. The project is modular, supports multi-user authentication, and is designed for future extensibility (e.g., gamification, analytics, cloud sync).

---

## Environment Setup & Installation

### Backend (FastAPI)
1. Create a virtual environment and activate it:
```bash
   cd backend
python3 -m venv .venv
   source .venv/bin/activate
```
2. Install dependencies:
```bash
pip install -r requirements.txt
```
3. Run the backend server:
   ```bash
   cd backend
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
   - The backend uses SQLite by default. To switch to PostgreSQL/MySQL, update `DATABASE_URL` in the `.env` file.

### Frontend (Flutter)
1. Install Flutter SDK (https://docs.flutter.dev/get-started/install)
2. Get dependencies:
   ```bash
   cd flutter_app
   flutter pub get
   ```
3. Run the app (choose your device/emulator):
```bash
   flutter run
   ```
   - Update `lib/src/config.dart` with your backend's IP if running on a real device.

### AI Integration
The app integrates with both OpenAI and Google Gemini AI models for the chatbot feature:

1. Set up API keys in the backend:
   - Create a `.env` file in the backend directory with:
   ```
   OPENAI_API_KEY=your_openai_api_key
   GEMINI_API_KEY=your_gemini_api_key
   ```
   - You can use either one or both APIs (the app will use available APIs)
   - Set `DEFAULT_AI_MODEL=openai` or `DEFAULT_AI_MODEL=gemini` to choose your preferred default

2. In the Flutter app:
   - The chat interface includes a dropdown to switch between models
   - The backend automatically handles API communication and error fallback

---

## Project Architecture

- **Backend:** FastAPI, SQLAlchemy, Alembic, JWT, Pydantic, SQLite (default)
- **Frontend:** Flutter, Provider, http, shared_preferences
- **AI Integration:** OpenAI API, Google Gemini API
- **Modular structure:**
  - Backend: `app/` (models, schemas, services, api, core, db)
  - Frontend: `lib/src/` (screens, models, services, providers, widgets)

---

## Current Progress
- ✅ FastAPI backend: user registration, login, JWT, user-specific task CRUD, task types (todo/long-term), user info API
- ✅ Flutter frontend: registration, login/logout, persistent login, Home (todo/complete/long-term), Chat, User/Profile, Provider state management, modern UI theme
- ✅ API integration: all requests use user id, baseUrl is globally configurable
- ✅ Multi-user support, SQLite auto-creates tables for dev/testing
- ✅ iOS/Android/web compatible, with network and permission fixes for real devices
- ✅ AI integration: OpenAI and Google Gemini support for the chat assistant
- ✅ TDD: core features covered by tests; more tests planned
- ✅ Deployment deferred: focus is on feature completion and robustness before cloud deployment

---

## Next Steps
- [ ] AI assistant / smart recommendation features (if needed)
- [ ] User profile editing, avatar and personalization features
- [ ] Further UI improvements (e.g., gradients, rounded corners, animations)
- [ ] Multi-environment auto-switching (dev/prod) and configuration management
- [ ] Add more test cases to improve robustness
- [ ] Calendar, progress tracking, and reflection pages
- [ ] LLM API integration (goal breakdown, smart suggestions)
- [ ] Local storage / offline support
- [ ] Documentation and handoff
- [ ] Deployment and production environment setup (scheduled for later)

---

## Vision & Features (Planned and Implemented)
- Goal breakdown and smart scheduling (AI-powered, in progress)
- User registration, login, and multi-user data isolation (done)
- Task CRUD, status, and type (done)
- Chat-based assistant for task creation (done)
- Progress tracking and adaptive planning (planned)
- Calendar and reflection tools (planned)
- Gamification, analytics, and cloud sync (future)
- Modern, mobile-friendly UI (done, ongoing polish)

---

## Team Contact
**Client:** Yuzhe Zhang  
📧 yuzhez23@uw.edu

**Developer:** Tressi Tian  
📧 tressi@uw.edu

---

## Notes
- This README reflects the current cross-platform (Flutter + FastAPI) architecture. The original Streamlit prototype is deprecated.
- Deployment is deferred until feature completion and robustness are achieved.
- For more details, see the `/backend` and `/flutter_app` directories.

