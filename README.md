# Biblio Fac

Application Flutter de gestion de bibliotheque universitaire (etudiants + administrateurs), basee sur Firebase (Authentication, Cloud Firestore, Storage) et Google Books API.

---

## Sommaire

- [Presentation](#presentation)
- [Fonctionnalites](#fonctionnalites)
- [Architecture](#architecture)
- [Stack technique](#stack-technique)
- [Prerquis](#prerequis)
- [Installation](#installation)
- [Configuration](#configuration)
- [Lancement](#lancement)
- [Structure du projet](#structure-du-projet)
- [Firestore](#firestore)
- [Script de seed (30 livres)](#script-de-seed-30-livres)
- [Depannage](#depannage)
- [Notes de securite](#notes-de-securite)
- [Licence](#licence)

---

## Presentation

`Biblio Fac` digitalise la gestion d'une bibliotheque universitaire:
- cote etudiant: consultation catalogue, reservations, demandes d'emprunt, suivi personnel
- cote admin: gestion complete des livres, utilisateurs, emprunts et reservations

Le projet suit une architecture `MVC + Provider`, avec des synchronisations en temps reel sur les operations critiques.

---

## Fonctionnalites

### 1) Authentification

- Inscription email/mot de passe (compte etudiant)
- Connexion email/mot de passe
- Connexion Google
- Deconnexion securisee
- Restauration automatique de session au demarrage (`SessionGate`)

### 2) Gestion des comptes etudiants

- Nouveau compte cree desactive par defaut (`isActive = false`)
- Activation/desactivation des etudiants par l'admin
- Message explicite d'attente d'activation pour compte non actif
- Blocage des operations bibliotheque tant que le compte n'est pas active

### 3) Catalogue de livres

- Affichage du catalogue
- CRUD admin (ajout, modification, suppression)
- Gestion du stock (`totalCopies`, `availableCopies`)
- Filtres/tri/recherche dans les ecrans de gestion

### 4) Emprunts

- Demande d'emprunt cote etudiant
- Validation/refus cote admin
- Marquage "retourne" cote admin
- Calcul d'echeance:
  - `loanDate` pose a l'approbation
  - `dueDate = loanDate + 14 jours`
  - `returnDate` renseignee au retour
- Mises a jour transactionnelles stock + statut

### 5) Reservations

- Reservation cote etudiant
- Traitement/annulation cote admin
- Suivi des statuts (`active`, `fulfilled`, `cancelled`)

### 6) Temps reel (Firestore snapshots)

- Emprunts: admin + etudiant
- Reservations: admin + etudiant
- Catalogue livres: synchro en live
- Utilisateurs (admin): synchro en live

### 7) Profil utilisateur

- Edition du profil etudiant
- Upload photo de profil (Firebase Storage)
- Controle de completude du profil (alertes champs manquants)
- Suppression de compte utilisateur

### 8) Integration Google Books API

- Recherche externe par:
  - titre
  - auteur
  - ISBN
- Import guide des metadonnees vers le catalogue local:
  - titre, auteur, ISBN, description, couverture, date de publication
- Verification anti-doublon ISBN avant import

---

## Architecture

Le projet suit `MVC + Provider`:

- `models/`: entites metier (`UserModel`, `BookModel`, `LoanModel`, `ReservationModel`, ...)
- `views/`: UI et ecrans
- `controllers/`: orchestration metier
- `services/`: acces Firebase/API externes
- `providers/`: etat applicatif et notifications UI

---

## Stack technique

- Flutter (Dart SDK `^3.10.7`)
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Provider (state management)
- Google Sign-In
- HTTP (Google Books API)
- Google Fonts
- Image Picker

---

## Prerequis

- Flutter SDK installe et configure
- Compte Firebase + projet Firebase
- Android Studio / VS Code
- Navigateur Chrome (si test web)
- Emulateur Android ou appareil physique

---

## Installation

```bash
git clone <url-du-repo>
cd biblio-fac-flutter
flutter pub get
```

---

## Configuration

### 1) Firebase

Verifier la presence/configuration:
- `lib/firebase_options.dart`
- `android/app/google-services.json`

### 2) Auth Google (Firebase)

Activer Google Sign-In dans Firebase Authentication.

### 3) Google Books API

Le projet lit la cle via `dart-define`:
- variable: `GOOGLE_BOOKS_API_KEY`

Exemple:
```bash
flutter run --dart-define=GOOGLE_BOOKS_API_KEY=VOTRE_CLE
```

Notes:
- en web local, utiliser de preference un port fixe
- restreindre la cle dans Google Cloud (API `Books API` + restrictions d'application)

### 4) Option .env

Un fichier `.env.example` est present pour documenter les cles, mais l'application utilise actuellement `--dart-define` pour injecter les secrets au runtime.

---

## Lancement

### Android (emulateur)
```bash
flutter run -d emulator-5554 --dart-define=GOOGLE_BOOKS_API_KEY=VOTRE_CLE
```

### Web (Chrome, port fixe recommande)
```bash
flutter run -d chrome --web-port 5000 --dart-define=GOOGLE_BOOKS_API_KEY=VOTRE_CLE
```

### Desktop Windows
```bash
flutter run -d windows --dart-define=GOOGLE_BOOKS_API_KEY=VOTRE_CLE
```

---

## Structure du projet

```text
lib/
  controllers/
  models/
  providers/
  services/
  utils/
  views/
    admin/
    auth/
    common/
    student/
  firebase_options.dart
  main.dart
scripts/
  seed_books_firestore.js
assets/
  images/
```

---

## Firestore

Collections principales:
- `users`
- `books`
- `loans`
- `reservations`

Relations:
- `loans.userId` -> `users.uid`
- `loans.bookId` -> `books.id`
- `reservations.userId` -> `users.uid`
- `reservations.bookId` -> `books.id`

---

## Script de seed (30 livres)

Script disponible: `scripts/seed_books_firestore.js`

1. Installer la dependance Node:
   - `npm install firebase-admin`
2. Placer la cle GCP `service-account.json` a la racine du projet
3. Test sans ecriture:
   - `node scripts/seed_books_firestore.js --dry-run`
4. Insertion:
   - `node scripts/seed_books_firestore.js`

Alternative:
- Utiliser `GOOGLE_APPLICATION_CREDENTIALS` + `GOOGLE_CLOUD_PROJECT`.

---

## Depannage

### 1) `permission-denied` Firestore
- Verifier les regles Firestore (create/update/read selon role)
- Verifier que le compte est bien authentifie et que le document user existe

### 2) Session web non persistante en local
- Utiliser un port fixe:
  - `flutter run -d chrome --web-port 5000`

### 3) Google Sign-In web
- Verifier la configuration Google/Firebase auth web
- Verifier les origines autorisees en console

### 4) Google Books API vide ou erreur
- Verifier la cle (`GOOGLE_BOOKS_API_KEY`)
- Verifier les restrictions de cle
- Verifier quota Google Cloud

---

## Notes de securite

- Ne pas committer de secrets (`API keys`, `service-account.json`, credentials)
- Utiliser `--dart-define` en local/CI
- Restreindre les cles API dans Google Cloud
- Garder les regles Firestore coherentes avec les roles applicatifs

---

## Licence

Ce projet est distribue sous la licence presente dans [LICENSE](LICENSE).
