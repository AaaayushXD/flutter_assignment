# Music & Utilities App

A comprehensive Flutter application featuring Firebase authentication, music management with YouTube integration, weather information, and utility tools.

## Features

### 🔐 Authentication

- **Email/Password Sign Up & Sign In**
- **Google Sign-In Integration**
- **Password Reset Functionality**
- **Secure Firebase Authentication**

### 🎵 Music Management

- **Add songs with title, playlist, and YouTube URL**
- **Create and manage playlists**
- **YouTube video player integration**
- **Song editing and deletion**
- **Playlist playback functionality**

### 🌤️ Weather

- **Real-time weather information**
- **Location-based weather data**
- **Beautiful weather UI with animations**

### 🛠️ Utilities

- **Counter with increment/decrement**
- **Timer with custom duration**
- **Stopwatch with lap times**
- **Expandable utility section**

## Setup Instructions

### 1. Firebase Configuration

1. **Create a Firebase Project:**

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select an existing one

2. **Enable Authentication:**

   - Go to Authentication > Sign-in method
   - Enable Email/Password authentication
   - Enable Google Sign-in (configure OAuth consent screen)

3. **Set up Firestore Database:**

   - Go to Firestore Database
   - Create a new database in test mode
   - Set up security rules for your collections

4. **Add Firebase to your Flutter app:**

   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

5. **Configure Android:**

   - Update `android/app/build.gradle.kts`:

   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("com.google.gms.google-services") // Add this line
   }
   ```

   - Update `android/build.gradle.kts`:

   ```kotlin
   dependencies {
       classpath("com.google.gms:google-services:4.4.0")
   }
   ```

6. **Configure iOS:**
   - Add the Firebase iOS SDK to your Podfile
   - Run `pod install` in the iOS directory

### 2. Environment Variables

Create a `.env` file in the root directory:

```
# Firebase Configuration
FIREBASE_API_KEY=your_api_key_here
FIREBASE_APP_ID=your_app_id_here
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_PROJECT_ID=your_project_id_here
FIREBASE_STORAGE_BUCKET=your_storage_bucket_here

# Weather API (if needed)
WEATHER_API_KEY=your_weather_api_key_here
```

### 3. Dependencies

The app uses the following key dependencies:

- `firebase_core`: Firebase core functionality
- `firebase_auth`: Authentication services
- `cloud_firestore`: Database services
- `google_sign_in`: Google Sign-In
- `youtube_player_flutter`: YouTube video player
- `provider`: State management
- `flutter_bloc`: BLoC pattern (for weather)

### 4. Running the App

1. **Install dependencies:**

   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── config/
│   └── firebase_config.dart
├── models/
│   ├── song_model.dart
│   └── weather_model.dart
├── pages/
│   ├── auth/
│   │   ├── login_page.dart
│   │   └── signup_page.dart
│   ├── songs_page.dart
│   ├── weather_page.dart
│   ├── utils_page.dart
│   └── main_navigation_page.dart
├── providers/
│   ├── auth_provider.dart
│   └── theme_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── song_service.dart
│   └── weather_service.dart
├── widgets/
│   ├── add_song_dialog.dart
│   └── youtube_player_widget.dart
└── main.dart
```

## Usage

### Authentication

1. Launch the app
2. Sign up with email/password or use Google Sign-In
3. After successful authentication, you'll be redirected to the Songs screen

### Music Management

1. **Adding Songs:**

   - Tap the + button on the Songs screen
   - Enter song title, playlist name, and YouTube URL
   - Save the song

2. **Managing Playlists:**

   - Switch to the Playlists tab
   - View all your playlists
   - Tap on a playlist to view its songs
   - Use the menu to play all songs or delete the playlist

3. **Playing Songs:**
   - Tap on any song to play it
   - Use the YouTube player controls
   - Navigate between songs in a playlist

### Utilities

1. Navigate to the Utils tab
2. Choose from Counter, Timer, or Stopwatch
3. Each utility has its own dedicated page with full functionality

## Security Rules for Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Songs can be read/written by authenticated users
    match /songs/{songId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please open an issue on GitHub or contact the development team.
