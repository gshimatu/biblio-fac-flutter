# Rapport Technique des Fonctionnalites - Biblio Fac

Date: 2026-02-25  
Projet: `biblio_fac`  
Objectif du document: lister et structurer les fonctionnalites effectivement implementees dans l'application, en les comparant au cahier des charges, puis identifier les fonctionnalites additionnelles hors cahier.

---

## 1. Perimetre audite

Ce rapport est base sur:
- le cahier des charges `Cahier des charges - Exam Flutter.pdf`
- l'analyse du code de production dans `lib/` (models, views, controllers, services, providers)
- la configuration technique Flutter/Firebase du projet (`pubspec.yaml`, `firebase_options.dart`, routes de `main.dart`)

---

## 2. Couverture du cahier des charges

### 2.1 Authentification et gestion des utilisateurs

Fonctionnalites demandees dans le cahier:
- inscription email/mot de passe
- connexion email/mot de passe
- connexion Google
- persistance de session
- deconnexion

Etat dans le projet:
- `Inscription email/mot de passe`: implementee avec creation du compte Firebase Auth + creation document `users/{uid}`.
- `Connexion email/mot de passe`: implementee.
- `Connexion Google`: implementee (web via `signInWithPopup`, mobile via `google_sign_in` + credential Firebase).
- `Persistance session`: implementee via `SessionGateView` + restauration automatique de session au demarrage.
- `Deconnexion securisee`: implementee.
- `Robustesse supplementaire`: gestion des comptes "orphelins" (Auth cree mais doc Firestore absent) via auto-recuperation et rollback de creation si echec Firestore.

Conclusion: couvert et depasse sur la robustesse.

### 2.2 Gestion du catalogue de livres

Fonctionnalites demandees:
- afficher la liste des livres
- ajouter/modifier/supprimer
- gerer stock total/disponible

Etat dans le projet:
- listing livres: implemente.
- CRUD admin complet: implemente.
- stock `totalCopies` / `availableCopies`: implemente.
- affichage detail livre cote etudiant: implemente.
- recherche et tri cote admin et etudiant: implemente.

Conclusion: couvert.

### 2.3 Emprunts et reservations

Fonctionnalites demandees:
- emprunt d'un livre disponible
- reservation d'un livre indisponible
- suivi statut emprunt
- historique emprunts utilisateur

Etat dans le projet:
- creation de demande d'emprunt et reservation cote etudiant: implementee.
- gestion statuts par admin:
  - emprunts: `pending`, `approved`, `returned`, `rejected`
  - reservations: `active`, `fulfilled`, `cancelled`
- historique emprunts et reservations cote etudiant: implemente.
- logique transactionnelle stock emprunt/retour:
  - approbation emprunt decremente `availableCopies`
  - retour incremente `availableCopies` (borne par `totalCopies`)
- gestion echeance:
  - a l'approbation admin, `loanDate = now`, `dueDate = now + 14 jours`
  - `returnDate` renseignee au retour

Conclusion: couvert et consolide.

### 2.4 Integration API externe (Google Books API)

Fonctionnalites demandees:
- recherche par titre/auteur/ISBN
- import auto des metadonnees principales

Etat dans le projet:
- service API externe dedie implemente (`GoogleBooksService`).
- recherche par mode `title`, `author`, `isbn`: implementee.
- import admin depuis API vers catalogue Firestore: implemente.
- donnees importees:
  - titre, auteur, ISBN (priorite ISBN13), description, couverture, date publication
- anti-doublon ISBN avant import: implemente.

Conclusion: couvert.

### 2.5 Architecture et gestion d'etat

Cahier:
- MVC + Provider

Etat:
- structure `models/views/controllers/services/providers`: en place.
- Provider utilise pour auth, livres, emprunts.
- separation des responsabilites globalement respectee.

Conclusion: couvert.

---

## 3. Fonctionnalites additionnelles (hors cahier ou approfondies)

Ces points ne sont pas explicitement imposes dans le cahier, ou sont implementes avec un niveau plus avance:

### 3.1 Activation manuelle des comptes etudiants
- nouveau compte etudiant cree desactive par defaut (`isActive: false`)
- activation/desactivation par admin dans gestion utilisateurs
- etudiant inactif peut se connecter mais ses operations bibliotheque sont bloquees
- message explicite d'attente d'activation visible dans l'espace etudiant

### 3.2 Controle de completude du profil etudiant
- indicateur d'alerte sur dashboard etudiant quand profil incomplet
- liste des champs obligatoires manquants sur l'ecran profil
- surlignage/indication de champs requis (photo exclue des obligations)

### 3.3 Temps reel Firestore (sync multi-utilisateurs)
- emprunts en temps reel (admin + etudiant)
- reservations en temps reel (admin + etudiant)
- catalogue livres en temps reel
- utilisateurs en temps reel cote admin
- impact concret: une demande creee par un etudiant apparait instantanement chez l'admin sans redemarrage

### 3.4 Session bootstrap avancee
- `SessionGateView` decide automatiquement la destination:
  - utilisateur non connecte -> accueil
  - admin -> dashboard admin
  - etudiant -> dashboard etudiant
- logs de diagnostic pour suivre la restauration de session

### 3.5 Gestion d'erreurs et experience utilisateur
- messages contextualises (snackbars, erreurs de formulaire, confirmations)
- boites de dialogue pour operations critiques (suppression, etc.)
- fallback et messages explicites pour erreurs de configuration auth/API

### 3.6 Gestion profil enrichie
- upload image profil Firebase Storage (mobile/web)
- suppression de compte avec nettoyage de donnees associees (dont image de profil si presente)

---

## 4. Mapping rapide par role

### 4.1 Etudiant
- inscription/connexion email
- connexion Google
- session persistante
- consultation catalogue + recherche
- reservation et demande d'emprunt
- suivi statuts emprunts/reservations
- profil editable + photo
- alertes profil incomplet
- blocage operationnel si compte non active

### 4.2 Administrateur
- dashboard statistiques
- gestion livres (CRUD + import Google Books)
- gestion utilisateurs (role, activation, suppression admin)
- gestion emprunts (approuver/refuser/retour)
- gestion reservations (traiter/annuler)
- vue temps reel des operations

---

## 5. Ecart fonctionnel residuel vis-a-vis du cahier

Sur le perimetre fonctionnel principal du cahier des charges, la couverture est globalement complete.

Points a surveiller pour la suite (non bloquants pour ce rapport):
- harmonisation finale de certains messages/encodages de texte FR dans l'UI
- stabilisation des warnings `info` restants (deprecations mineures Flutter)
- consolidation documentaire (README final) et procedure de lancement d'equipe (`--dart-define` pour la cle API Google Books)

---

## 6. Conclusion

Le projet implemente l'ensemble des fonctionnalites centrales prevues par le cahier des charges (auth, roles, catalogue, emprunts/reservations, API externe, architecture MVC + Provider).

En plus, des capacites "niveau production" ont ete ajoutees:
- flux temps reel multi-acteurs
- activation admin des comptes etudiants
- controle de completude profil
- fiabilisation du cycle auth/firestore
- transactions coherentes pour stock et retours.


