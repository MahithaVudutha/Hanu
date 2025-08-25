## Divine Guide (SwiftUI + Firebase + HuggingFace)

Divine Guide is a kid-friendly spiritual guidance iOS app delivering verses and life lessons from Mahabharata, Ramayanam, Hanuman Chalisa, Sai Baba Charitra, Quran, and Bible. It includes a multilingual AI assistant (Telugu, Hindi, English, Urdu), speech input, and text-to-speech output. Built with SwiftUI (iOS 16+), Firebase (Auth + Firestore), and free-tier HuggingFace Inference API for translation/NLP.

### Features
- Login/Signup/Forgot password with Firebase Auth
- Menu for 6 sources: Mahabharata, Ramayanam, Hanuman Chalisa, Sai Baba Charitra, Quran, Bible
- AI chat: type or speak mood/problem; get relevant verse + explanation + life lesson
- Multilingual (Telugu, Hindi, English, Urdu) with TTS
- Favorites and offline caching (Firestore local persistence + JSON cache)

### Project Structure
```
DivineGuide/
  project.yml                 # XcodeGen spec (open in Xcode after generating .xcodeproj)
  .gitignore
  Config/
    Secrets.example.plist     # Copy to Secrets.plist and fill keys
  FirebaseRules/
    firestore.rules
  FirestoreSeed/
    sample_scriptures.json
  DivineGuide/
    DivineGuideApp.swift
    Info.plist
    Models/
    Services/
    ViewModels/
    Views/
    Resources/
      Assets.xcassets/
      Colors.xcassets/
      Images.xcassets/
```

### Prerequisites
- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed (brew install xcodegen)
- Firebase project (free tier)
- HuggingFace API token (free tier)

### 1) Generate Xcode project
```bash
cd DivineGuide
xcodegen generate
open DivineGuide.xcodeproj
```

If you prefer without XcodeGen, you can also create a new SwiftUI App in Xcode and import the `DivineGuide/` sources, add Firebase SPM package, and include `Info.plist`, `GoogleService-Info.plist`, and `Config/Secrets.plist` to the target.

### 2) Firebase setup
1. In Firebase Console → Add iOS app with bundle id: com.yourorg.DivineGuide
2. Download `GoogleService-Info.plist` and add to `DivineGuide/` target in Xcode.
3. In Xcode, select project → target → Signing & Capabilities → add `Push Notifications` (optional), `Background Modes` (Audio if you plan TTS in background), not required otherwise.
4. Enable Authentication (Email/Password) and Firestore in Firebase Console.

### 3) Secrets setup (HuggingFace API)
1. Copy `Config/Secrets.example.plist` → `Config/Secrets.plist`
2. Fill `HUGGINGFACE_API_TOKEN`
3. In Xcode, ensure `Secrets.plist` is added to the app target.

To run without external APIs, leave `HUGGINGFACE_API_TOKEN` blank. The app will use heuristic mood detection and skip translation.

### 4) Firestore rules (basic free-tier safety)
See `FirebaseRules/firestore.rules`. In Firebase Console → Firestore → Rules → publish these.

### 5) Seeding example scriptures
Use `FirestoreSeed/sample_scriptures.json` as a guide. You can upload via Firebase Console → Firestore Data → Import (or write minimal docs manually). Required fields:
- source (string: mahabharata|ramayanam|hanuman_chalisa|sai_baba|quran|bible)
- verse_ref (string)
- language (string: en, hi, te, ur)
- text (string)
- explanation (string, English preferred)
- tags (array of strings like ["sad", "hope", "courage"]) for mood mapping

Example Firestore document (JSON):
```
{
  "source": "mahabharata",
  "verse_ref": "Bhagavad Gita 2.47",
  "language": "en",
  "text": "You have a right to perform your prescribed duty, but you are not entitled to the fruits of action.",
  "explanation": "Focus on effort, not outcomes. Do your best, let go of results.",
  "tags": ["anxiety", "stress", "general"]
}
```

### 6) App Store build & deploy
1. In Xcode, set your team and unique bundle id.
2. Product → Archive → Distribute App → App Store Connect → Upload.
3. In App Store Connect, create app record, fill privacy policy, data usage, and content review notes.
4. Add testers in TestFlight → submit for review → publish.

Tips for $0 deployment:
- Use Firebase free tier only (email/password auth, Firestore reads within free quota).
- HuggingFace free token has rate limits; app gracefully works offline with cached content.
- No paid Apple services; only standard developer account is required.

### Privacy & Compliance
- Uses Apple Speech framework for STT (no server-side speech unless you add it).
- TTS via AVSpeechSynthesizer.
- All external calls (HuggingFace) use HTTPS and are optional; the app remains useful with local data.
- Provide a simple in-app parental guide and gentle content.

Data collected: email for auth, optional favorites list. No tracking. Update App Privacy details accordingly in App Store Connect. Provide a short in-app note in Settings if needed.

### Notes
- If HuggingFace API token is missing, the app gracefully falls back to English or simple rule-based responses.
- Firestore offline persistence is enabled; verses are cached on first load.

