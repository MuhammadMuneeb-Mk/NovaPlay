# 🎮 NovaPlay – Game Store App

NovaPlay is a full‑stack mobile application where users can browse, buy, download (simulated), and manage games. It features a shopping cart, user authentication, persistent cart, game management for admins, and a carousel of featured games.

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
git clone https://github.com/Muneeb-Khan-mk/NovaPlay.git
cd NovaPlay
