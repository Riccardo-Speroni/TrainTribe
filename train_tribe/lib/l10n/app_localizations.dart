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
      'logout' : 'Logout',
      'complete_profile': 'Complete your profile',

      // User Information
      'choose_username': 'Choose a username',
      'username': 'Username',
      'name_surname': 'Name Surname',
      'enter_email': 'Enter email',
      'invalid_email': 'Invalid email',
      'phone_number': 'Phone number',
      'add_phone_number': 'Add your Phone Number',
      'your_email': 'Your email',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'choose_profile_picture': 'Choose a profile picture',
      'pick_image': 'Pick an Image',

      // Password
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
      'onboarding_desc_1': 'Your ultimate app for managing your training sessions.',
      'onboarding_title_2': 'Track Your Progress',
      'onboarding_desc_2': 'Monitor your training and stay motivated.',
      'onboarding_title_3': 'Connect with Friends',
      'onboarding_desc_3': 'Share your progress and train together.',
      'onboarding_title_4': 'Achieve Your Goals',
      'onboarding_desc_4': 'Stay consistent and reach your fitness milestones.',
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

      // Miscellaneous
      'contacts_access': 'Contacts Access',
      'location_access': 'Location Access',
      'mood_status': 'Mood Status reset frequency',
      'before_each_event': 'Before Each Event',
      'daily': 'Daily',
      'never': 'Never',
      'mood_question': 'Are you in the mood?',
      'add_or_search_friends': 'Add or search friends',
      'next': 'Next',
      'verify': 'Verify',
      'edit': 'Edit',
      'ghost': 'Ghost',
      'whatsapp': 'Whatsapp',
      'phone_number_note': 'Optional. Used only for retrieving contacts as friends.',
      'generate_avatars': 'Generate Avatars',

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
    },
    'it': {
      // General
      'settings': 'Impostazioni',
      'language': 'Lingua',
      'theme': 'Tema',
      'light': 'Chiaro',
      'dark': 'Scuro',
      'system': 'Sistema',

      // Navigation
      'home': 'Casa',
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
      'logout' : 'Disconnetti',
      'complete_profile': 'Completa il tuo profilo',

      // User Information
      'username': 'Nome utente',
      'choose_username': 'Scegli un nome utente',
      'name_surname': 'Nome Cognome',
      'enter_email': 'Inserisci email',
      'invalid_email': 'Email non valida',
      'phone_number': 'Numero di telefono',
      'add_phone_number': 'Aggiungi il tuo numero di telefono',
      'your_email': 'La tua email',
      'first_name': 'Nome',
      'last_name': 'Cognome',
      'choose_profile_picture': 'Scegli una foto profilo',
      'pick_image': 'Scegli un\'immagine',

      // Password
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
      'onboarding_desc_1': 'La tua app definitiva per gestire le tue sessioni di allenamento.',
      'onboarding_title_2': 'Monitora i tuoi progressi',
      'onboarding_desc_2': 'Tieni traccia dei tuoi allenamenti e rimani motivato.',
      'onboarding_title_3': 'Connettiti con gli amici',
      'onboarding_desc_3': 'Condividi i tuoi progressi e allenati insieme.',
      'onboarding_title_4': 'Raggiungi i tuoi obiettivi',
      'onboarding_desc_4': 'Rimani costante e raggiungi i tuoi traguardi di fitness.',
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

      // Miscellaneous
      'contacts_access': 'Accesso ai contatti',
      'location_access': 'Accesso alla posizione',
      'mood_status': 'Frequenza di reset dello stato',
      'before_each_event': 'Prima di ogni evento',
      'daily': 'Giornaliero',
      'never': 'Mai',
      'mood_question': 'Sei dell\'umore giusto?',
      'add_or_search_friends': 'Aggiungi o cerca amici',
      'next': 'Avanti',
      'verify': 'Verifica',
      'edit': 'Modifica',
      'ghost': 'Nascondi',
      'whatsapp': 'Whatsapp',
      'phone_number_note': 'Opzionale. Usato solo per recuperare i contatti come amici.',
      'generate_avatars': 'Genera Avatar',

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