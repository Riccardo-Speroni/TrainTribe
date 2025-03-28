import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // Traduzioni
  static final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'mood_status': 'Mood Status reset frequency',
      'before_each_event': 'Before Each Event',
      'daily': 'Daily',
      'never': 'Never',
      'home': 'Home',
      'friends': 'Friends',
      'trains': 'Trains',
      'calendar': 'Calendar',
      'profile': 'Profile',
      'english': 'English',
      'italian': 'Italian',
      'username': 'Username',
      'name_surname': 'Name Surname',
      'email': 'Email',
      'phone_number': 'Phone number',
      'edit': 'Edit',
      'verify': 'Verify',
      'mood_question': 'Are you in the mood?',
      'new_event': 'New Event',
      'edit_event': 'Edit Event',
      'event_title': 'Event Title',
      'duration': 'Duration',
      'hours': 'hours',
      'at': 'at',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'ghost': 'Ghost',
      'whatsapp': 'Whatsapp',
      'add_or_search_friends': 'Add or search friends',
      'choose_username': 'Choose a username',
      'next': 'Next',
      'sign_in_google': 'Sign in with Google',
      'sign_in_facebook': 'Sign in with Facebook',
      'already_have_account': 'Already have an account? Login',
      'choose_password': 'Choose a password',
      'repeat_password': 'Repeat the password',
      'confirm_password': 'Confirm Password',
      'add_phone_number': 'Add your Phone Number',
      'your_email': 'Your email',
      'first_name': 'First Name',
      'last_name': 'Last Name',
      'choose_profile_picture': 'Choose a profile picture',
      'pick_image': 'Pick an Image',
      'create_account': 'Create Account',
      'login': 'Login',
      'login_google': 'Login with Google',
      'login_facebook': 'Login with Facebook',
      'dont_have_account': "Don't have an account? Sign up",
      'contacts_access': 'Contacts Access',
      'location_access': 'Location Access',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System',
    },
    'it': {
      'settings': 'Impostazioni',
      'language': 'Lingua',
      'mood_status': 'Frequenza di reset dello stato',
      'before_each_event': 'Prima di ogni evento',
      'daily': 'Giornaliero',
      'never': 'Mai',
      'home': 'Casa',
      'friends': 'Amici',
      'trains': 'Treni',
      'calendar': 'Calendario',
      'profile': 'Profilo',
      'english': 'Inglese',
      'italian': 'Italiano',
      'username': 'Nome utente',
      'name_surname': 'Nome Cognome',
      'email': 'Email',
      'phone_number': 'Numero di telefono',
      'edit': 'Modifica',
      'verify': 'Verifica',
      'mood_question': 'Sei dell\'umore giusto?',
      'new_event': 'Nuovo Evento',
      'edit_event': 'Modifica Evento',
      'event_title': 'Titolo Evento',
      'duration': 'Durata',
      'hours': 'ore',
      'at': 'alle',
      'save': 'Salva',
      'cancel': 'Annulla',
      'delete': 'Elimina',
      'ghost': 'Nascondi',
      'whatsapp': 'Whatsapp',
      'add_or_search_friends': 'Aggiungi o cerca amici',
      'choose_username': 'Scegli un nome utente',
      'next': 'Avanti',
      'sign_in_google': 'Accedi con Google',
      'sign_in_facebook': 'Accedi con Facebook',
      'already_have_account': 'Hai già un account? Accedi',
      'choose_password': 'Scegli una password',
      'repeat_password': 'Ripeti la password',
      'confirm_password': 'Conferma Password',
      'add_phone_number': 'Aggiungi il tuo numero di telefono',
      'your_email': 'La tua email',
      'first_name': 'Nome',
      'last_name': 'Cognome',
      'choose_profile_picture': 'Scegli una foto profilo',
      'pick_image': 'Scegli un\'immagine',
      'create_account': 'Crea Account',
      'login': 'Accedi',
      'login_google': 'Accedi con Google',
      'login_facebook': 'Accedi con Facebook',
      'dont_have_account': 'Non hai un account? Registrati',
      'contacts_access': 'Accesso ai contatti',
      'location_access': 'Accesso alla posizione',
      'theme': 'Tema',
      'light': 'Chiaro',
      'dark': 'Scuro',
      'system': 'Sistema',
    },
  };

  String translate(String key) {
    return _localizedStrings[locale.languageCode]?[key] ?? key;
  }

  String languageCode(){
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