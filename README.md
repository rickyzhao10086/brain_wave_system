# brain_wave_system

NeuroMotion uses the MUSE 2, a low-cost wireless EEG headband, to capture brainwaves from the patient and stream them over Bluetooth to a Python desktop application. The desktop tool filters the signal, computes power across the delta, theta, alpha, beta, and gamma bands, and sends those features to the OpenAI API, which returns a predicted state — calm, elevated, or distress. The result is pushed to a Flutter mobile app that shows a single traffic-light indicator (green, yellow, or red) so therapists and caregivers can react without having to read the EEG itself.

# Screens
- Home: stats summary
    - patient status
    - recent EEG readings
- Session: TBD
- Analysis: TBD
- Model: 
    - information about the current models used in the desktop app + the LLM APIs that you are using
- Profile: info about the patient
    - picture
    - name
    - body measurements:
        - exercise history
        - TBD
    - description
