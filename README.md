# biblio_fac

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Seed Firestore (30 livres)

Script disponible: `scripts/seed_books_firestore.js`

1. Installer la dependance:
   - `npm install firebase-admin`
2. Placer votre cle GCP `service-account.json` a la racine du projet.
3. Lancer un test sans ecriture:
   - `node scripts/seed_books_firestore.js --dry-run`
4. Inserer les 30 livres:
   - `node scripts/seed_books_firestore.js`

Option alternative (sans fichier local):
- Exporter `GOOGLE_APPLICATION_CREDENTIALS` et `GOOGLE_CLOUD_PROJECT`, puis lancer le script.
