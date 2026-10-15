# 🎮 NovaPlay – Game Store App

NovaPlay is a full‑stack mobile application where users can browse, buy, download (simulated), and manage games. It features a shopping cart, user authentication, persistent cart, game management for admins, and a carousel of featured games.

**Web demo:** https://muhammadmuneeb-mk.github.io/NovaPlay/ (click "Demo account" on the login screen)

The web demo uses sample data instead of the real backend, see [Web demo](#-web-demo) below.

---

## 📖 Description

NovaPlay is a Flutter‑based game storefront backed by a Node.js REST API and a MySQL database. Users can sign up, log in, explore a list of games, view detailed game information, add games to a persistent shopping cart, purchase games (simulated), and download owned games. Admins can perform full CRUD operations on the game catalogue. The app supports theme switching (light/dark/system), search, sorting, and filtering.

---

## ✨ Features

### User Features
- **Authentication** – Sign up, log in, and forgot password (dummy reset).
- **Home Screen** – Browse all games, search by title, sort by title (A‑Z, Z‑A) or price (low‑high, high‑low), and view a carousel of featured games (first 5 games).
- **Game Detail** – See full game info (description, requirements, rating, content rating). Buy a game (adds to owned games) or add to cart.
- **Shopping Cart** – Persistent cart stored locally using SharedPreferences. Add/remove items, validate against owned games, checkout (demo).
- **Library** – View owned games (purchased games). Search, filter by installed (downloaded) games, and sort alphabetically. Download games (5‑second simulation) or play (demo snackbar).
- **Downloads** – View downloaded games, simulate download (5 seconds), delete downloads.
- **Profile** – Edit username, email, display name (requires current password). Change password with separate dialog (verifies current password).
- **Theme** – Switch between light, dark, and system themes.
- **Beta Screen** – Explore all games in a carousel + full list (accessible from Settings).

### Admin Features
- **Admin Panel** – Full CRUD (Create, Read, Update, Delete) for games (protected by JWT). Add/edit game with title, image path, description, price.

### Backend API (Node.js + MySQL)
- **Users CRUD** – Signup, login (returns JWT), get all users, get single user, update profile (requires current password), change password, delete user.
- **Games CRUD** – Public GET endpoints, protected POST/PUT/DELETE.
- **Purchases** – Record purchases (`POST /api/purchases`) and retrieve owned games (`GET /api/users/me/games`).
- **JWT Authentication** – Protected routes require a valid token.
- **CORS enabled** – Works with Flutter app on emulator or real device.

### Technical Highlights
- **Flutter** – Provider for state management, SharedPreferences for persistent cart, HTTP requests with custom `ApiClient`.
- **Node.js** – Express, MySQL2, JSON Web Tokens, bcrypt (optional for production).
- **MySQL** – Tables: `games`, `users`, `purchases`.

---

## 🌐 Web demo

The demo is the same Flutter app built for the web with `--dart-define=DEMO_MODE=true`. In that mode all requests go to `lib/services/mock_backend.dart` instead of the Node.js server. It has the same routes as `backend/server.js` (login, signup, games CRUD, purchases, profile) and saves data in the browser, so nothing needs to be hosted except static files.

It is deployed to GitHub Pages by `.github/workflows/deploy-web-demo.yml` when `main` is pushed.

---

## 🛠️ Technologies Used

### Frontend (Flutter)
- Flutter SDK (Dart)
- Provider (state management)
- SharedPreferences (persist cart and token)
- HTTP (API communication)

### Backend (Node.js)
- Node.js + Express.js
- MySQL2 (database driver)
- JSON Web Token (jwt)
- CORS, dotenv

### Database
- MySQL (or MariaDB)

---

## 🚀 Setup Instructions

### Prerequisites
- **Flutter SDK** (≥ 3.0) – [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Node.js** (≥ 16) and npm – [Download Node.js](https://nodejs.org/)
- **MySQL** (or XAMPP/WAMP for local MySQL server) – [Download MySQL](https://dev.mysql.com/downloads/)
- **Git** (optional) – to clone the repository

### 1. Clone the repository
```bash
git clone https://github.com/MuhammadMuneeb-Mk/NovaPlay.git
cd NovaPlay
```

### 2. Run without the backend (demo mode)
```bash
flutter pub get
flutter run -d chrome --dart-define=DEMO_MODE=true
```

### 3. Run with the real backend
1. Create a MySQL database with `games`, `users` and `purchases` tables (columns as used in `backend/server.js`).
2. In `backend/`, create a `.env` file with `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` and `JWT_SECRET`, then start the API:
   ```bash
   cd backend
   npm install express mysql2 cors jsonwebtoken dotenv
   node server.js
   ```
3. Run the app. It connects to `http://localhost:3000` on the web and `http://10.0.2.2:3000` on the Android emulator (see `lib/app_config.dart`):
   ```bash
   flutter run
   ```
