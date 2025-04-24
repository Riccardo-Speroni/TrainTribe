# ⚙️ Setup per collaboratori

Questo progetto utilizza **Firebase** come backend. Segui attentamente i passaggi per configurare il tuo ambiente di sviluppo e collaborare senza problemi.

## 0. Requisiti minimi

Assumiamo che tu abbia già:

- Flutter installato e funzionante
- Git configurato
- VS Code o Xcode installati
- Il progetto già clonato da GitHub e con le ultime modifiche

## 1. Ottieni i file privati da aggiungere al progetto

Chiedi all’amministratore i seguenti file Firebase:

| File                       | Dove va inserito                    |
|----------------------------|-------------------------------------|
| `google-services.json`     | `android/app/`                      |
| `GoogleService-Info.plist` | `ios/Runner/`                       |
| `firebase_options`         | `lib/`                              |

Questi file **non sono presenti** nel repository perché sono sensibili. Non vanno mai pushati su GitHub.
Sono già dentro al gitignore.

## 2. Accesso al progetto Firebase

Per poter utilizzare Firebase, devi essere aggiunto come **Editor** al progetto Firebase.

### Cosa fare:

1. Invia al team la tua email Gmail
2. Verrai aggiunto su [Firebase Console](https://console.firebase.google.com/) > ⚙️ Impostazioni > Accesso e autorizzazioni > Aggiungi utente > Ruolo: **Editor**

##  3. Installa Firebase CLI

Firebase CLI è uno strumento da riga di comando necessario per configurare il progetto Firebase in Flutter.

### Step A — Installa Node.js

Scarica e installa Node.js da:  
🔗 https://nodejs.org/en/download

### Step B — Installa Firebase CLI

Apri il terminale o PowerShell e lancia:

`npm install -g firebase-tools`

`firebase login`

Dovrebbe reindirizzare e aspettare che facciate da browser il login su firebase con la vostra mail google.

#### Problema comune su Windows

Se su PowerShell ricevi un errore come:

`Impossibile caricare il file npm.ps1. L'esecuzione di script è disabilitata nel sistema in uso.`

Allora apri PowerShell come amministratore ed esegui:

`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`

Poi riprova a installare Firebase CLI.

## 4. Ultimi passi

Fare un `flutter pub get`

## Cose da non pushare

Elenco di file sensibili da non pushare, già presenti nel gitignore, ma da controllare almeno la prima volta:

- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist
- .firebase/
- .dart_tool/
- firebase_options.dart

## Nota per Ricky

### Per configurare iOS con Firebase:

Apri Xcode (il tuo collega Mac deve farlo):

Trascina il file nella cartella ios/Runner in Xcode

Assicurati che sia incluso nel target Runner

In ios/Podfile, abilita la piattaforma:

`platform :ios, '11.0'`

Fai un:

`flutter pub get`
`cd ios`
`pod install`
`cd ..`

Il tuo collega con Mac può testare l’app su simulatore iOS e tutto funzionerà. Il codice Dart è lo stesso identico, cambia solo la configurazione Firebase.