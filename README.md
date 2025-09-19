# LapaBricks

A Flutter application featuring secure email/password authentication with fingerprint login, QR code scanning, and Firebase integration.

---

## 🚀 Features

- **Email & Password Login:** Secure authentication using Firebase.
- **Biometric Authentication:** Login with fingerprint (using device sensor).
- **QR Code Scanning:** Scan QR codes via device camera.
- **Profile Management:** Edit user profile and manage settings.
- **Forgot Password:** Password reset via email.
- **Persistent Secure Login:** Credentials stored securely for biometric access.

---

## 📱 Screenshots

<!-- Add screenshots here if available
![Login Screenshot](screens/login.png)
![Dashboard Screenshot](screens/dashboard.png)
-->

---

## 🛠️ Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://firebase.google.com/)
- Device/emulator with fingerprint sensor (for biometric login)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/kirtan1232/LapaBricks.git
   cd LapaBricks
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase**
   - Add your Firebase configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
   - Enable Email/Password authentication in Firebase Console.

4. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔒 Permissions

**Android:**
- Camera: For QR code scanning
- Biometric: For fingerprint login

**iOS:**
- Camera usage description in `Info.plist`
- Face ID usage description in `Info.plist`

---

## 📦 Dependencies

- [`firebase_auth`](https://pub.dev/packages/firebase_auth)
- [`cloud_firestore`](https://pub.dev/packages/cloud_firestore)
- [`local_auth`](https://pub.dev/packages/local_auth)
- [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage)

---

## 🙋‍♂️ Contribution

Pull requests are welcome!  
For major changes, please open an issue first to discuss what you would like to change.

---

## 📄 License

[MIT](LICENSE)

---

## 👤 Author

**Kirtan**  
[GitHub](https://github.com/kirtan1232) | [LinkedIn](https://www.linkedin.com/in/kirtan1232/)
