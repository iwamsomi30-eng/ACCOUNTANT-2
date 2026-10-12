# Kusakinisha Mfumo wa Makusanyo ya Pesa

## Hatua ya mara moja: sahihi ya Android (ili update zisakinishe juu ya toleo la zamani)

Tengeneza keystore mara moja kwenye kompyuta yako (hifadhi faili na nywila mahali salama, usiipoteze):

    keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Kisha base64 ya faili (Windows PowerShell):

    [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard

Ingia GitHub: Settings > Secrets and variables > Actions > New repository secret, weka:

- ANDROID_KEYSTORE_BASE64  (ulichonakili hapo juu)
- ANDROID_KEYSTORE_PASSWORD
- ANDROID_KEY_ALIAS  (upload)
- ANDROID_KEY_PASSWORD

## Android
Pakua `Makusanyo-Android-Zote.apk` kutoka Actions > Artifacts.
Inafanya kazi kwenye simu za arm64, armeabi-v7a na x86_64.
Kwenye simu: ruhusu "Install unknown apps" kwa app uliyotumia kufungua APK (Chrome/Files), kisha sakinisha.

## Windows (Windows 10 na 11, 64-bit; ARM64 kupitia emulation ya x64 ya Windows 11)
- `Makusanyo-Setup.exe`: bonyeza mara mbili. Haihitaji Administrator. Ikionyesha "Windows protected your PC", bonyeza "More info" kisha "Run anyway".
- `Makusanyo-Windows-Portable.zip`: kama installer imezuiwa, toa (extract) zip yote kwenye folda, kisha bonyeza `makusanyo.exe`.
- Visual C++ runtime imejumuishwa ndani ya app; PC safi hazihitaji kusakinisha chochote.

## Zisizowezekana
Windows 7/8/8.1 na Windows 32-bit hazitumiki na Flutter, kwa hiyo app hii haiwezi kufanya kazi huko.
