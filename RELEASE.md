# Releasing the Yes Dhobi Partner app (riders and laundry shops)

Everything in the repo is ready. What is left needs your developer accounts and
your signing key, which only you can hold.

| | |
| --- | --- |
| App name | Yes Dhobi Partner |
| Android package | `com.yesdhobi.partner` |
| iOS bundle id | `com.yesdhobi.partner` |
| Version | `1.0.0+1` (set in `pubspec.yaml`) |

> The package used to be `com.example.yesdhobi_ridervendor`. Both stores reject
> anything starting `com.example`, so it has been renamed. Nothing was
> published under the old id, so there is nothing to migrate.

---

## Before you start: two things that will cost you weeks if you skip them

**1. Check your Play Console account type — do this today.**

Play Console → Setup → Account details. If it is a **personal** account created
after 13 November 2023, Google will not grant production access until you have
run a closed test with **12 testers opted in continuously for 14 days**.
Organisation accounts are exempt.

Your own riders are ideal testers for this app, so the 14-day clock costs you
nothing but calendar time — start it now.

**2. The API must be on HTTPS before the iPhone app can ship.**

The app talks to `http://yesdhobi-alb-…elb.amazonaws.com`. Android tolerates it
because the app declares cleartext traffic. **iOS blocks it outright** — on an
iPhone every request fails, so the app does not work at all, never mind pass
review.

The fix is `api.yesdhobi.com` with a free ACM certificate: about 30 minutes plus
DNS propagation, steps in `backend/DEPLOY.md` section 11.3 of the `yes-dhobi`
repo. Then change `baseUrl` in `lib/services/api_client.dart` to
`https://api.yesdhobi.com/api/v1`.

Android can ship before this. iOS cannot.

---

## Android — Play Store

### Step 1. Create the signing key (once, ever)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Put `upload-keystore.jks` in the `android/` folder, copy
`android/key.properties.example` to `android/key.properties`, and fill in the
passwords you chose.

**Back both files up somewhere safe.** Lose the keystore and you can never
update this app again — you would need a new listing and every rider would have
to reinstall. Nobody can recover it for you. Both are gitignored.

Use a **different** keystore from the customer app, or the same one — either
works, but keep whichever you choose consistent and backed up.

### Step 2. Build

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

Without step 1 the build still succeeds but is debug-signed, and Play rejects it.

### Step 3. Upload

Play Console → Create app → listing → Production (or Closed testing for the
14-day requirement) → upload the `.aab`.

---

## iOS — App Store

**Cannot be done from Windows.** Building for iOS needs macOS and Xcode. Use a
Mac, or a cloud Mac service like Codemagic or Bitrise.

1. Apple Developer Program — $99/year; company enrolment needs a D-U-N-S number
   and takes a few days.
2. On the Mac: `flutter build ipa --release`
3. Open `build/ios/archive/Runner.xcarchive` in Xcode → Distribute App → App
   Store Connect.
4. Fill in the App Store Connect listing and submit. Review is usually 1–3 days.

---

## Store listing content

- **Short description** (Play, 80 chars): For Yes Dhobi delivery partners and
  laundry shops. Accept orders and track earnings.
- **Full description**: Riders receive nearby pickup requests, navigate to the
  customer, and confirm handovers with an OTP. Laundry partners accept orders,
  update progress and request payouts.
- **Screenshots**: at least 2 for Play, 3 for Apple (6.7" and 6.5").
- **App icon**: 512×512 for Play, 1024×1024 for Apple.
- **Feature graphic** (Play only): 1024×500.
- **Privacy policy URL** — **required by both.** Host one, e.g.
  `https://yesdhobi.com/partner-privacy`.
- **Category**: Business. **Content rating**: everyone.

### This app will get extra scrutiny — be ready for it

It is a closed app for your own staff and partners, which both stores question.

- **Apple will reject it** unless you give reviewers a working login. Create a
  test rider account, approve it in the admin panel, and put the Registration
  ID / phone and password in the App Review notes, with a line saying the app
  is for onboarded delivery partners only. Without this it is rejected as
  "incomplete" or "for a limited audience".
- **Play will ask about the foreground location and notifications.** Answer
  honestly: location is used while a rider is on an active delivery so the
  customer can track them; it is not collected in the background.

### Play Data Safety answers

| Data | Collected | Shared | Why |
| --- | --- | --- | --- |
| Name, phone, email | Yes | No | Partner account and contacting about orders |
| Precise + approximate location | Yes | No | Matching riders to nearby orders and live tracking during a delivery |
| Photos | Yes | No | ID documents and the verification selfie during onboarding |
| Bank / UPI details | Yes | No | Paying out earnings |
| Government ID (Aadhaar, PAN) | Yes | No | KYC verification, required to work as a partner |

Encrypted in transit. Deletion on request through support.

> Government ID and bank details are sensitive categories. Declare them. Play
> will suspend the app if it finds them undeclared.

### Permissions, and what to say if review asks

| Permission | Why |
| --- | --- |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Talking to the Yes Dhobi API |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Offering a rider the nearest job and letting the customer track them during a delivery. Foreground only |
| `CAMERA` | Capturing ID documents and the verification selfie at onboarding. Gallery upload is deliberately disabled so the photo must be live |
| `POST_NOTIFICATIONS` | Alerting a rider to a new pickup offer — they have 15 seconds to respond |
| `USE_FULL_SCREEN_INTENT` | Showing that offer over the lock screen, as a rider is usually not looking at the phone. **Play requires a separate declaration for this** — in the form, say it is a time-critical job offer with a 15-second window |
| `FOREGROUND_SERVICE`, `WAKE_LOCK`, `VIBRATE` | Staying reachable for offers while the app is backgrounded during a shift |

---

## Before you submit, check these

- [ ] Play account type checked; closed test started if it is a personal account
- [ ] `OtpDevMode=false` on the backend
- [ ] Test partner account created **and approved in the admin panel**, with
      credentials in the Apple review notes
- [ ] `USE_FULL_SCREEN_INTENT` declaration completed in Play Console
- [ ] Privacy policy published
- [ ] HTTPS live, if submitting to Apple
