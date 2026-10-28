# Prywatne aktualizacje Pokémon 100%

## Co przygotowano w kodzie

- Aplikacja sprawdza aktualizacje po uruchomieniu i co 24 godziny, gdy proces aplikacji pozostaje uruchomiony.
- Jeśli Google Play udostępnia nowszą wersję, aplikacja pokazuje okno z opcją „Aktualizuj teraz”.
- Ustawienia zawierają ręczne sprawdzenie aktualizacji oraz status konfiguracji push.
- Klient Firebase Cloud Messaging jest przygotowany, ale pozostaje nieaktywny do czasu konfiguracji Firebase.
- Żaden token GitHuba, klucz konta usługi ani sekret Firebase nie jest przechowywany w kodzie aplikacji.

## Google Play — prywatne testowanie

1. Utwórz lub skonfiguruj aplikację w Google Play Console.
2. Przed publikacją wybierz unikalny identyfikator pakietu. Obecny applicationId to com.example.pokemon_100 i jest przykładowy; należy go zmienić przed pierwszym wydaniem, a potem zachować bez zmian.
3. Ważne: obecny android/app/build.gradle.kts ustawia dla wariantu release podpisywanie kluczem debug. Przed publikacją trzeba skonfigurować bezpieczne podpisywanie release i zachować klucz/konfigurację podpisu. Nie publikuj wersji podpisanej kluczem debug.
4. Włącz testy wewnętrzne i dodaj konto Google testera.
5. Zbuduj i prześlij Android App Bundle (flutter build appbundle --release) zgodnie z konfiguracją podpisywania, a następnie zainstaluj aplikację z linku testowego Google Play.
6. Każda kolejna wersja musi mieć większy versionCode (Flutter: liczba po znaku + w pubspec.yaml), a test aktualizacji należy wykonać na aplikacji zainstalowanej z Google Play. Funkcja in-app update nie działa dla lokalnie instalowanego APK.

## Firebase Cloud Messaging — powiadomienia push

1. Utwórz prywatnie zarządzany projekt w Firebase Console i dodaj aplikację Android z dokładnie tym samym identyfikatorem pakietu, którego używa Google Play.
2. Skonfiguruj Firebase dla Fluttera zgodnie z oficjalnym przewodnikiem: https://firebase.google.com/docs/cloud-messaging/flutter/get-started
3. Pobierz plik google-services.json i umieść go lokalnie w android/app/. Nie dodawaj do repozytorium żadnych kluczy kont usługi ani tokenów wysyłających wiadomości. Przed commitem sprawdź .gitignore i status Git.
4. Dokończ konfigurację Google Services Gradle plugin zgodnie z aktualnym przewodnikiem Firebase dla Androida. Dopiero po dodaniu pliku i pluginu można aktywować FCM; obecny kod celowo przechwytuje błąd braku konfiguracji, aby aplikacja mogła się uruchomić.
5. Włącz uprawnienia powiadomień w Androidzie. Użytkownik może je odmówić lub wyłączyć w ustawieniach systemu.
6. Do wysyłania powiadomień użyj Firebase Console lub zaufanego backendu/Cloud Functions. Nigdy nie umieszczaj klucza serwisowego ani poświadczeń FCM w aplikacji mobilnej.
7. Wyślij testową wiadomość z treścią powiadomienia na urządzenie testera. Sprawdź zachowanie, gdy aplikacja jest na pierwszym planie, w tle i zamknięta.

## Ważne ograniczenia

- Powiadomienia push nie są aktywne, dopóki nie zostanie skonfigurowany projekt Firebase i Android.
- Codzienne sprawdzanie aktualizacji działa podczas działania procesu aplikacji; po zamknięciu aplikacji nie jest to zadanie gwarantowane przez system. Przy następnym uruchomieniu sprawdzenie nastąpi ponownie.
- Google Play może rozprowadzać aktualizacje automatycznie według ustawień sklepu, a własne okno aktualizacji jest dodatkową ścieżką.
- Nie wykonano w tej zmianie flutter pub get, flutter analyze, testów ani kompilacji. Wymagana jest weryfikacja lokalna przed uznaniem funkcji za działające.
