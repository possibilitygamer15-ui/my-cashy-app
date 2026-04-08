# CashyPro (Flutter + Firebase)

Professional Android earning app with OTP/Google login, rewarded ads, tasks, spin, scratch, wallet, withdrawals, referral, and admin panel.

## 1) Setup

1. Install Flutter stable and verify:
   ```bash
   flutter --version
   flutter doctor
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Add Android package name in `android/app/build.gradle` and `google-services.json`.

## 2) Firebase Integration

1. Create Firebase project.
2. Enable products:
   - Authentication: Phone + Google
   - Firestore
   - Cloud Messaging
3. Add Android app SHA-1 and SHA-256.
4. Download `google-services.json` to `android/app/`.
5. Add `com.google.gms.google-services` plugin in Gradle files.
6. Create Firestore indexes for:
   - `transactions`: `uid ASC, timestamp DESC`
   - `tasks`: `isActive ASC`
   - `withdrawals`: `status ASC`

## 3) Firestore Collections

- `users/{uid}`
  - uid, name, phone, coins, balance, referrals, referralCode, role, adViewsToday, adViewsDate, lastSpinDate
- `tasks/{taskId}`
  - title, link, rewardCoins, isActive
- `transactions/{id}`
  - uid, type, amount, description, status, timestamp
- `withdrawals/{id}`
  - uid, amount, upiId, status, createdAt

## 4) Security Rules (starter)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() { return request.auth != null; }
    function isAdmin() {
      return signedIn() && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{uid} {
      allow read: if signedIn() && request.auth.uid == uid;
      allow write: if signedIn() && request.auth.uid == uid;
    }

    match /tasks/{taskId} {
      allow read: if signedIn();
      allow write: if isAdmin();
    }

    match /transactions/{txId} {
      allow read: if signedIn() && resource.data.uid == request.auth.uid;
      allow create: if signedIn();
      allow update, delete: if false;
    }

    match /withdrawals/{id} {
      allow create: if signedIn() && request.resource.data.uid == request.auth.uid;
      allow read: if signedIn() && resource.data.uid == request.auth.uid || isAdmin();
      allow update: if isAdmin();
    }
  }
}
```

## 5) AdMob Integration

1. Create AdMob app + rewarded ad unit.
2. Replace test ad unit in `lib/services/ad_service.dart` with production ad unit.
3. Add `com.google.android.gms.ads.APPLICATION_ID` to `AndroidManifest.xml`.
4. Policy compliance:
   - Reward only on full watch callback.
   - Enforce max 10 rewarded ads/day.

## 6) Business Logic Implemented

- OTP + Google authentication.
- Referral rewards for both new and invited user.
- Daily spin wheel (one spin/day) with 10 coin entry fee and 5–50 coin reward range.
- Scratch card with 25% payout probability.
- Task validation timer (8 seconds) before reward claim.
- Anti-abuse checks:
  - Daily ad cap
  - One-time task completion
  - One spin/day
- Wallet:
  - 100 coins = ₹10 conversion
  - Withdrawal minimum ₹50
  - Pending/Approved/Rejected state
- Admin:
  - Add tasks
  - Approve/reject withdrawal requests

## 7) Build & Deploy

```bash
flutter build apk --release
flutter build appbundle --release
```

Upload AAB to Play Console internal testing, then production rollout.
