
# brain_wave_system

NeuroMotion uses the MUSE 2, a low-cost wireless EEG headband, to capture brainwaves from the patient and stream them over Bluetooth to a Python desktop application. The desktop tool filters the signal, computes power across the delta, theta, alpha, beta, and gamma bands, and sends those features to the OpenAI API, which returns a predicted state — calm, elevated, or distress. The result is pushed to a Flutter mobile app that shows a single traffic-light indicator (green, yellow, or red) so therapists and caregivers can react without having to read the EEG itself.

NeuroMotion 使用 MUSE 2（一款低成本的无线脑电（EEG）头带）来采集患者的脑电波，并通过蓝牙将其传输到一个 Python 桌面应用程序。该桌面工具对信号进行滤波，计算 delta、theta、alpha、beta 和 gamma 各频段的功率，并将这些特征发送到 OpenAI API，由其返回一个预测状态——平静（calm）、亢奋（elevated）或痛苦（distress）。结果随后被推送到一个 Flutter 移动应用，应用以单个交通灯式指示器（绿、黄或红）显示状态，使治疗师和护理人员无需自己解读脑电图即可作出反应。

# Screens
- Home: stats summary
    - patient status
    - recent EEG readings
- Analysis: Show how the health reading of the person wearing the device
- Model: 
    - information about the current models used in the desktop app + the LLM APIs that you are using
- Profile: info about the patient
    - picture
    - name
    - body measurements:
        - exercise history
        - TBD
    - description


Doctors and Nurses ONLY use the desktop app