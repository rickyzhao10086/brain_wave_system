# CerebroSync

CerebroSync is a Flutter prototype for live Muse 2 sessions. The mobile app can
connect directly to a Muse 2 over Bluetooth Low Energy and decode its sensor
packets on the phone. Firebase and persisted session records are not connected.

## Direct phone test

No Python process is required for this path.

1. Stop `muselsl stream` and close any Muse or BLE scanner app. A Muse 2 can
   normally serve only one active Bluetooth client.
2. Turn the Muse 2 off and back on, then leave it close to the phone.
3. Connect a physical iPhone or Android phone to the development Mac. BLE is not
   available in the iOS Simulator or most Android emulators.
4. From this directory, list the available targets and run the app:

```bash
flutter devices
flutter run -d YOUR_PHONE_DEVICE_ID
```

5. Accept the Bluetooth or Nearby Devices permission prompt.
6. Continue as guest, open the `Device` tab, and tap `Scan for Muse 2`.

The app scans for devices whose advertised name starts with `Muse`, connects,
subscribes to EEG, PPG, accelerometer, gyroscope, and telemetry characteristics,
then sends the Muse `d` command to begin streaming.

If no headband is found, make sure MuseLSL is stopped, power-cycle the headband,
and retry. Do not pair the Muse manually in the phone's Bluetooth settings; the
app connects to it as a BLE peripheral.

## Current direct-mode scope

- Four EEG channels at 256 Hz: TP9, AF7, AF8, and TP10.
- Three Muse 2 PPG channels at 64 Hz, with an early pulse-rate estimate.
- Accelerometer and gyroscope motion summaries.
- Battery telemetry when the headband sends it.
- Relative EEG band power computed locally in Dart.
- Foreground sessions only. Background streaming and automatic reconnection are
  not enabled yet.
- Contact quality, pulse rate, EEG state, and artifact labels are prototype
  estimates. They are not medical measurements or validated classifications.

## Developer bridge fallback

The previous MuseLSL bridge remains available for comparison and debugging.
Start MuseLSL:

```bash
muselsl stream --address AD79EE5E-9B4D-98BC-A3A7-C554593F6542 --ppg --acc --gyro
```

Start the bridge in another terminal:

```bash
~/.local/pipx/venvs/muselsl/bin/python tools/muse_lsl_bridge.py
```

Run Flutter on the Mac or simulator, then choose `Connect developer bridge` in
the Device tab:

```bash
flutter run
```

The default bridge URL is `ws://127.0.0.1:8765`. It can still be overridden
with `--dart-define=MUSE_WS_URL=ws://HOST:8765`.
