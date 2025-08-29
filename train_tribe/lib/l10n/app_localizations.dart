import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Categorized translations
  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      // General
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
      'back': 'Back',
      'reset_onboarding': 'Repeat onboarding',

      // Navigation
      'home': 'Home',
      'friends': 'Friends',
      'trains': 'Trains',
      'calendar': 'Calendar',
      'profile': 'Profile',

      // Authentication
      'login_google': 'Sign in with Google',
      'login_facebook': 'Sign in with Facebook',
      'already_have_account': 'Already have an account? Login',
      'dont_have_account': "Don't have an account? Sign up",
      'login': 'Login',
      'create_account': 'Create Account',
      'login_failed': 'Login failed',
      'login_error_credentials': 'Invalid credentials. Please try again.',
      'login_error_no_internet': 'No internet connection. Please check your network.',
      'login_error_generic': 'An unexpected error occurred. Please try again later.',
      'login_error_user_disabled': 'User account has been disabled.',
      'firebase_windows_error': 'Something went wrong. Please check the credentials and your internet connection.',
      'logout': 'Logout',
      'complete_profile': 'Complete your profile',

      // User Information
      'choose_username': 'Choose a username',
      'username': 'Username',
      'name': 'Name',
      'name_surname': 'Name Surname',
      'email': 'Email',
      'enter_email': 'Enter email',
      'invalid_email': 'Invalid email',
      'phone_number': 'Phone number',
      'add_phone_number': 'Add your Phone Number',
      'your_email': 'Your email',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'surname': 'Surname',
      'choose_profile_picture': 'Choose a profile picture',
      'pick_image': 'Pick an Image',
      'remove_image': 'Remove Image',
      'copy_username': 'Copy username',
      'more': 'Generate new avatars',
      'copied': 'Copied!',

      // Password
      'password': 'Password',
      'choose_password': 'Choose a password',
      'repeat_password': 'Repeat the password',
      'confirm_password': 'Confirm Password',
      'password_min_length': 'At least 8 characters',
      'password_uppercase': 'At least one uppercase letter',
      'password_lowercase': 'At least one lowercase letter',
      'password_number': 'At least one number',
      'passwords_match': 'Passwords match',
      'passwords_do_not_match': 'Passwords do not match',

      // Onboarding
      'onboarding_title_1': 'Welcome to TrainTribe',
      'onboarding_desc_1': 'Instantly see which friends might be on the same train as you.',
      'onboarding_title_2': 'Add Your Contacts',
      'onboarding_desc_2': 'Turn phone contacts into TrainTribe friends in one tap.',
      'onboarding_title_3': 'Plan Your Time Windows',
      'onboarding_desc_3': 'Set when you can travel plus origin and destination — we\'ll match the options.',
      'onboarding_title_4': 'Choose Your Combination',
      'onboarding_desc_4': 'Compare train options and see which friends are on each one.',
      'onboarding_title_5': 'Enjoy the Trip Together',
      'onboarding_desc_5': 'Travel with friends and make every journey more fun.',
      'skip': 'Skip',
      'finish': 'Finish',

      // Events
      'new_event': 'New Event',
      'edit_event': 'Edit Event',
      'event_title': 'Event Title',
      'duration': 'Duration',
      'hours': 'hours',
      'at': 'at',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'saved': 'Saved',
      'departure': 'Departure Station',
      'arrival': 'Arrival Station',
      'day': 'Day',
      'start_hour': 'Start Hour',
      'end_hour': 'End Hour',
      'recurrent': 'Recurrent',
      'end_recurrence': 'End Recurrence',
      'invalid_station_name': 'Invalid station name',
      'confirm_delete': 'Confirm Delete',
      'delete_event_confirmation': 'Are you sure you want to delete this event?',
      'yes': 'Yes',
      'no': 'No',

      // Notifications
      'new_friend_request': 'New friend request',
      'new_friend_request_body': 'sent you a friend request.',
      'new_friend': 'New Friend',
      'request_accepted': 'has accepted your friend request.',

      // Miscellaneous
      'contacts_access': 'Contacts Access',
      'location_access': 'Location Access',
      'mood_status': 'Mood Status reset frequency',
      'before_each_event': 'Before Each Event',
      'daily': 'Daily',
      'never': 'Never',
      'mood_question_1': 'Are you in the mood?',
      'mood_question_2': 'Wanna meet some friends?',
      'mood_question_3': 'What about some chit-chat?',
      'mood_question_4': 'Why traveling alone?',
      'mood_question_5': 'Tired of being bored?',
      'add_or_search_friends': 'Add or search friends',
      'next': 'Next',
      'verify': 'Verify',
      'edit': 'Edit',
      'ghost': 'Ghost',
      'whatsapp': 'Whatsapp',
      'phone_number_note': 'Optional. Used only for retrieving contacts as friends.',
      'example': 'Example',
      'generate_avatars': 'Generate Avatars',
      'search_and_add_friends_hint': 'Type to filter your friends. Press enter or the button to search and add new friends.',
      'search_and_add_friends_tooltip': 'Search and add new friends',
      'prefix': 'Prefix',
      'find_from_contacts': 'Find from contacts',
      'suggested_from_contacts': 'Suggested from contacts',
      'no_contact_suggestions': 'No suggestions from your contacts',
      'phone_required_for_suggestions': 'Add your phone number in your profile to get suggestions from contacts.',
      'confirm': 'Confirm',
      'confirmed': 'Confirmed',
      // Train confirmations tooltips
      'you_confirmed_train': 'You confirmed this train',
      'you_not_confirmed_train': 'You have not confirmed a train yet',
      'friend_confirmed_train': 'Confirmed this train',
      'friend_not_confirmed_train': 'Has not confirmed a train yet',
      'train_confirm_legend_title': 'Train confirmation legend',
      'train_confirm_legend_you': 'Green ring: train you confirmed',
      'train_confirm_legend_friend': 'Amber ring + check: friend confirmed',
      'train_confirm_legend_unconfirmed': 'Plain avatar: not confirmed',
      'train_confirm_info': 'You can confirm only one train per event. Re-confirming moves your selection.',

      // Error Messages
      'error': 'Error',
      'ok': 'OK',
      'unexpected_error': 'An unexpected error occurred. Please try again.',
      'error_email_already_in_use': 'This email is already in use. Please use a different email.',
      'error_invalid_email': 'The email address is not valid.',
      'error_operation_not_allowed': 'Email/password accounts are not enabled. Please contact support.',
      'error_weak_password': 'The password is too weak. Please use a stronger password.',
      'error_username_taken': 'This username is already taken. Please choose another one.',
      'error_too_many_requests': 'Too many requests. Please try again later.',
      'error_user_token_expired': 'Your session has expired. Please log in again.',
      'error_network_request_failed': 'Network error. Please check your internet connection.',
      'error_unexpected': 'An unexpected error occurred. Please try again.',
      'error_loading_profile': 'Error loading profile',
      'friend_requests': 'Friend Requests',
      'accept': 'Accept',
      'decline': 'Decline',
      'unghost': 'Un-ghost',
      'no_friends_found': 'No friends found',
      'add_new_friends': 'Add new friends',
      'add_friend': 'Add friend',
      'request_sent': 'Request sent',
      'no_trains_found': 'No trains have been found',
      'invalid_phone': 'Invalid phone. Use a prefix followed by 10 digits (e.g., +39 345 1234567).',
      'invalid': 'Invalid',
      'contacts_permission_denied': 'Contacts permission denied. Please enable it in settings.',
    },
    'it': {
      // General
      'settings': 'Impostazioni',
      'language': 'Lingua',
      'theme': 'Tema',
      'light': 'Chiaro',
      'dark': 'Scuro',
      'system': 'Sistema',
      'back': 'Indietro',
      'reset_onboarding': 'Ripeti onboarding',

      // Navigation
      'home': 'Home',
      'friends': 'Amici',
      'trains': 'Treni',
      'calendar': 'Calendario',
      'profile': 'Profilo',

      // Authentication
      'login_google': 'Accedi con Google',
      'login_facebook': 'Accedi con Facebook',
      'already_have_account': 'Hai già un account? Accedi',
      'dont_have_account': 'Non hai un account? Registrati',
      'login': 'Accedi',
      'create_account': 'Crea Account',
      'login_failed': 'Accesso fallito',
      'login_error_credentials': 'Credenziali non valide. Riprova.',
      'login_error_no_internet': 'Nessuna connessione a internet. Controlla la tua rete.',
      'login_error_generic': 'Si è verificato un errore inaspettato. Per favore riprova più tardi.',
      'login_error_user_disabled': 'L\'account è stato disabilitato.',
      'firebase_windows_error': 'Qualcosa è andato storto. Controlla le credenziali e la tua connessione a internet.',
      'logout': 'Disconnetti',
      'complete_profile': 'Completa il tuo profilo',

      // User Information
      'username': 'Nome utente',
      'choose_username': 'Scegli un nome utente',
      'name': 'Nome', 
      'name_surname': 'Nome Cognome',
      'email': 'Email',
      'enter_email': 'Inserisci email',
      'invalid_email': 'Email non valida',
      'phone_number': 'Numero di telefono',
      'add_phone_number': 'Aggiungi il tuo numero di telefono',
      'your_email': 'La tua email',
      'first_name': 'Nome',
      'last_name': 'Cognome',
      'surname': 'Cognome',
      'choose_profile_picture': 'Scegli una foto profilo',
      'pick_image': 'Scegli un\'immagine',
      'remove_image': 'Rimuovi immagine',
      'copy_username': 'Copia nome utente',
      'more': 'Genera altri avatar',
      'copied': 'Copiato!',

      // Password
      'password': 'Password',
      'choose_password': 'Scegli una password',
      'repeat_password': 'Ripeti la password',
      'confirm_password': 'Conferma Password',
      'password_min_length': 'Almeno 8 caratteri',
      'password_uppercase': 'Almeno una lettera maiuscola',
      'password_lowercase': 'Almeno una lettera minuscola',
      'password_number': 'Almeno un numero',
      'passwords_match': 'Le password corrispondono',
      'passwords_do_not_match': 'Le password non corrispondono',

      // Onboarding
      'onboarding_title_1': 'Benvenuto in TrainTribe',
      'onboarding_desc_1': 'Scopri subito chi dei tuoi amici potrebbe essere sul tuo stesso treno.',
      'onboarding_title_2': 'Importa i tuoi contatti',
      'onboarding_desc_2': 'Aggiungi i contatti e trasformali in amici TrainTribe con un tap.',
      'onboarding_title_3': 'Pianifica le tue fasce orarie',
      'onboarding_desc_3': 'Indica quando puoi partire e le stazioni di origine e destinazione: penseremo noi a incrociare le opzioni.',
      'onboarding_title_4': 'Scegli la tua combinazione',
      'onboarding_desc_4': 'Confronta le opzioni di treno e scopri quali amici ci sono.',
      'onboarding_title_5': 'Goditi il viaggio insieme',
      'onboarding_desc_5': 'Viaggia con gli amici e rendi ogni spostamento più divertente.',
      'skip': 'Salta',
      'finish': 'Fine',

      // Events
      'new_event': 'Nuovo Evento',
      'edit_event': 'Modifica Evento',
      'event_title': 'Titolo Evento',
      'duration': 'Durata',
      'hours': 'ore',
      'at': 'alle',
      'save': 'Salva',
      'cancel': 'Annulla',
      'delete': 'Elimina',
      'saved': 'Salvato',
      'departure': 'Stazione di Partenza',
      'arrival': 'Stazione di Arrivo',
      'day': 'Giorno',
      'start_hour': 'Ora di Inizio',
      'end_hour': 'Ora di Fine',
      'recurrent': 'Ricorrente',
      'end_recurrence': 'Fine Ricorrenza',
      'invalid_station_name': 'Nome stazione non valido',
      'confirm_delete': 'Conferma Eliminazione',
      'delete_event_confirmation': 'Sei sicuro di voler eliminare questo evento?',
      'yes': 'Sì',
      'no': 'No',

      // Notifications
      'new_friend_request': 'Nuova richiesta di amicizia',
      'new_friend_request_body': 'ti ha inviato una richiesta di amicizia.',
      'new_friend': 'Nuovo Amico',
      'request_accepted': 'ha accettato la tua richiesta di amicizia.',

      // Miscellaneous
      'contacts_access': 'Accesso ai contatti',
      'location_access': 'Accesso alla posizione',
      'mood_status': 'Frequenza di reset dello stato',
      'before_each_event': 'Prima di ogni evento',
      'daily': 'Giornaliero',
      'never': 'Mai',
      'mood_question_1': 'Sei dell\'umore giusto?',
      'mood_question_2': 'Vuoi incontrare degli amici?',
      'mood_question_3': 'Vuoi chiacchierare?',
      'mood_question_4': 'Perché viaggiare da soli?',
      'mood_question_5': 'Stanco di annoiarti?',
      'add_or_search_friends': 'Aggiungi o cerca amici',
      'next': 'Avanti',
      'verify': 'Verifica',
      'edit': 'Modifica',
      'ghost': 'Nascondi',
      'whatsapp': 'Whatsapp',
      'phone_number_note': 'Opzionale. Usato solo per recuperare i contatti come amici.',
      'example': 'Esempio',
      'generate_avatars': 'Genera Avatar',
      'search_and_add_friends_hint': 'Scrivi per filtrare i tuoi amici. Premi invio o il pulsante per cercare e aggiungere nuovi amici.',
      'search_and_add_friends_tooltip': 'Cerca e aggiungi nuovi amici',
      'prefix': 'Prefisso',
      'find_from_contacts': 'Trova dai contatti',
      'suggested_from_contacts': 'Suggeriti dai contatti',
      'no_contact_suggestions': 'Nessun suggerimento dai tuoi contatti',
      'phone_required_for_suggestions': 'Aggiungi il tuo numero di telefono nel profilo per ottenere suggerimenti dai contatti.',
      'confirm': 'Conferma',
      'confirmed': 'Confermato',
      // Train confirmations tooltips
      'you_confirmed_train': 'Hai confermato questo treno',
      'you_not_confirmed_train': 'Non hai ancora confermato un treno',
      'friend_confirmed_train': 'Ha confermato questo treno',
      'friend_not_confirmed_train': 'Non ha ancora confermato un treno',
      'train_confirm_legend_title': 'Legenda conferma treno',
      'train_confirm_legend_you': 'Bordo verde: treno che hai confermato',
      'train_confirm_legend_friend': 'Bordo ambra + check: amico che ha confermato',
      'train_confirm_legend_unconfirmed': 'Avatar semplice: non confermato',
      'train_confirm_info': 'Puoi confermare solo un treno per evento. Riconfermare sposta la tua selezione.',

      // Error Messages
      'error': 'Errore',
      'ok': 'OK',
      'unexpected_error': 'Si è verificato un errore inaspettato. Riprova.',
      'error_email_already_in_use': 'Questa email è già in uso. Usa un\'altra email.',
      'error_invalid_email': 'L\'indirizzo email non è valido.',
      'error_operation_not_allowed': 'Gli account email/password non sono abilitati. Contatta il supporto.',
      'error_weak_password': 'La password è troppo debole. Usa una password più forte.',
      'error_username_taken': 'Questo nome utente è già in uso. Scegline un altro.',
      'error_too_many_requests': 'Troppe richieste. Riprova più tardi.',
      'error_user_token_expired': 'La tua sessione è scaduta. Accedi di nuovo.',
      'error_network_request_failed': 'Errore di rete. Controlla la tua connessione a internet.',
      'error_unexpected': 'Si è verificato un errore inaspettato. Riprova.',
      'error_loading_profile': 'Errore nel caricamento del profilo',
      'friend_requests': 'Richieste di amicizia',
      'accept': 'Accetta',
      'decline': 'Rifiuta',
      'unghost': 'Rendi visibile',
      'no_friends_found': 'Nessun amico trovato',
      'add_new_friends': 'Aggiungi nuovi amici',
      'add_friend': 'Aggiungi amico',
      'request_sent': 'Richiesta inviata',
      'no_trains_found': 'Non è stato trovato nessun treno',
      'invalid_phone': 'Numero non valido. Scrivi un prefisso seguito da 10 cifre (es. +39 345 1234567).',
      'invalid': 'Non valido',
      'contacts_permission_denied': 'Permesso contatti negato. Abilitalo nelle impostazioni.',
    },
  };

  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }

  String languageCode() {
    return locale.languageCode;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'it'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
