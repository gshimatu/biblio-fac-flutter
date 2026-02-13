# Résolution du problème d'affichage de la photo de profil sur Firebase Storage

## Contexte
Dans notre application Flutter, après avoir implémenté l'upload d'image de profil vers Firebase Storage, nous avons rencontré deux problèmes :
1. **Erreur 403 (Unauthorized)** lors de l'upload.
2. **Erreur CORS** lors de l'affichage de l'image sur le web.

Ce document explique étape par étape comment résoudre ces problèmes.

---

## Étape 1 : Règles Firebase Storage permissives (pour diagnostic)

Dans la console Firebase, nous avons modifié les règles de **Storage** pour autoriser temporairement tout utilisateur authentifié à lire et écrire. Cela a permis de vérifier que l'upload fonctionnait correctement.

**Règles utilisées :**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}


Après cette modification, l'upload a réussi (l'image apparaissait dans Firebase Storage), mais l'affichage dans l'application web échouait avec une erreur CORS.

## Etape 2 : Configuration CORS pour autoriser les requêtes depuis le navigateur
L'erreur CORS indiquait que le navigateur bloquait l'accès à l'image car le serveur (Firebase Storage) ne renvoyait pas l'en-tête Access-Control-Allow-Origin. Pour réoudre cela, nous avons configuré les règles CORS du bucket.

### 2.1 Installation de Google Cloud SDK (gcloud et gsutil)
Nous avons installé le Google Cloud SDK qui fournit l'outil gsutil nécessaire pour modifier la configuration CORS.

Téléchargement : [Google Cloud SDK Installer](https://docs.cloud.google.com/sdk/docs/install-sdk?hl=fr)

Suivre les instructions d'installation pour Windows (ou autre OS).

Après installation, lancer le Google Cloud SDK Shell (en tant qu'administrateur si nécessaire).

### 2.2 Authentification avec gcloud
Dans le shell, nous nous sommes connectés avec le compte Google propriétaire du projet Firebase :

```bash
gcloud auth login
```
Une page web s'ouvre pour autoriser l'accès. Une fois authentifié, le message suivant apparaît :

```text
You are now logged in as [votre-email@gmail.com].
```
### 2.3 Création du fichier CORS JSON
Nous avons créé un fichier cors.json dans le dossier du projet Flutter avec le contenu suivant :

```json
[
  {
    "origin": ["http://localhost"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Content-Length", "Content-Encoding", "Cache-Control"]
  }
]
```
### 2.4 Application de la configuration CORS
Dans le shell, après s'être placé dans le dossier contenant cors.json :

```bash
cd D:\apkflutter\Examen\biblio-fac-flutter
gsutil cors set cors.json gs://biblio-fac.firebasestorage.app
```
Vérification :

```bash
gsutil cors get gs://biblio-fac.firebasestorage.app
```
La configuration était bien prise en compte, mais l'erreur CORS persistait car le port de l'application changeait à chaque exécution (ex: http://localhost:48899).

## Etape 3 : Utilisation du wildcard * pour autoriser toutes les origines
Pour éviter de devoir lister tous les ports possibles, nous avons modifié le fichier cors.json pour autoriser toutes les origines avec le wildcard * :

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Content-Length", "Content-Encoding", "Cache-Control"]
  }
]
```
Puis réapplication :

```bash
gsutil cors set cors.json gs://biblio-fac.firebasestorage.app
```
Pourquoi le wildcard est acceptable ici ?
Les URLs des images contiennent un token d'authentification (?alt=media&token=...). Cela sécurise l'accès même si l'origine est ouverte à tous. Ainsi, le wildcard ne pose pas de problème de sécurité.

## Etape 4 : Nettoyage du cache navigateur
Après la modification, nous avons effectué un rechargement forcé du navigateur (Ctrl+Shift+R) pour vider le cache et forcer la prise en compte des nouveaux en-têtes CORS.

Résultat : L'image de profil s'affiche correctement dans l'application web, quel que soit le port utilisé par Flutter.

## Etape 5 : Retour aux règles de sécurité strictes (recommandé)
Une fois le problème résolu, nous avons rétabli des règles de sécurité plus strictes pour Firebase Storage :

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```
Ces règlent garantissent que :

Seul un utilisateur authentifié peut lire les images.

Seul le propriétaire de l'image (dont l'UID correspond à celui dans le chemin) peut écrire (uploader, modifier, supprimer).

## Conclusion
Nous avons résolu le problème en combinant :

Vérification des règles Firebase Storage.

Authentification avec gcloud.

Configuration CORS avec gsutil.

Utilisation du wildcard * pour s'adapter aux ports variables du développement web.

Liens utiles :

[Télécharger Google Cloud SDK](https://docs.cloud.google.com/sdk/docs/install-sdk?hl=fr)

[Documentation Firebase Storage](https://firebase.google.com/docs/storage?hl=fr)

[Configuration CORS pour Firebase Storage](https://firebase.google.com/docs/storage/web/download-files?hl=fr#cors_configuration)
