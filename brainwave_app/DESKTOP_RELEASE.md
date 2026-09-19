# CerebroSync desktop release

The desktop targets are distributed from the CerebroSync website, not through
an app store. A Flutter desktop release is a bundle, not a single file: keep
the Windows `data` directory and DLLs beside the `.exe`, and keep the complete
macOS `.app` bundle intact.

## One-time setup

Windows builds require Flutter desktop support, Visual Studio 2022 with the
**Desktop development with C++** workload, and a Windows 10/11 SDK. macOS
builds require Flutter desktop support, Xcode, and the Xcode command-line tools.

The app uses the existing Firebase project `cerebrosync-b79a9`. Before the
first macOS release, add a macOS app in Firebase with bundle ID
`com.codingminds.cerebrosync`, then regenerate `lib/firebase_options.dart` with
the FlutterFire CLI. The checked-in desktop options currently include the
existing development/default macOS registration; a website release should use
the registration that matches the bundle ID above. Windows uses the web
Firebase configuration because the Windows Firebase plugins are initialized
from the supplied `FirebaseOptions`.

## Build and package Windows

Run this from `brainwave_app` on a Windows build machine:

```powershell
powershell -ExecutionPolicy Bypass -File tools/build_windows_release.ps1 `
  -Version 1.0.0 -BuildNumber 1
```

The script produces:

- `dist/windows/CerebroSync-windows-x64-v1.0.0.zip`
- the matching `.sha256` checksum file

Upload the ZIP as the website download. Do not upload only
`CerebroSync.exe`; the executable depends on the adjacent Flutter runtime,
plugins, DLLs, and `data` directory.

For a polished public release, Authenticode-sign the executable and bundled
DLLs with the Coding Minds Academy Windows certificate before creating the ZIP,
then verify the signature on a clean Windows machine.

## Build and package macOS

Run this from `brainwave_app` on a Mac build machine:

```bash
bash tools/build_macos_release.sh 1.0.0 1
```

This creates a ZIP containing `CerebroSync.app` and, when `hdiutil` is
available, a DMG as well. Verify the architecture before publishing:

```bash
lipo -info build/macos/Build/Products/Release/CerebroSync.app/Contents/MacOS/CerebroSync
```

For website distribution, sign with a **Developer ID Application** identity
and notarize with Apple. The script supports this through
`MACOS_SIGNING_IDENTITY`, `NOTARIZE=1`, `APPLE_ID`, `APPLE_TEAM_ID`, and
`APPLE_APP_PASSWORD`. Use an app-specific password for notarization. A
notarized build is important because an unsigned download will otherwise be
blocked or warned about by Gatekeeper on other Macs.

## Release smoke test

On clean Windows and macOS machines:

1. Install or extract the artifact without Flutter or the repository present.
2. Launch CerebroSync and complete email/password sign-in.
3. Confirm the Device screen starts in clearly labeled Mock mode.
4. Turn on Bluetooth, scan for a Muse 2, and verify the direct BLE session.
5. Confirm a cloud-recorded session appears in Session History and that the
   developer bridge failure remains a harmless, readable error.
6. Check that the Privacy Policy and Support links open in the system browser.

The desktop app uses the same Firebase rules, account deletion flow, and
non-clinical wellness labeling as the mobile app. Desktop builds should not be
published until the macOS Firebase registration, Windows code-signing choice,
and macOS notarization status are confirmed.
