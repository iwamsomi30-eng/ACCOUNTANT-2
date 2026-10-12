; Installer ya Windows - Mfumo wa Makusanyo ya Pesa (WAWATA)
#define MyAppName "Mfumo wa Makusanyo ya Pesa"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "WAWATA"
#define MyAppExeName "makusanyo.exe"

[Setup]
AppId={{B3A1C7E2-5D4F-4A8B-9C21-7E0F1A2B3C4D}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\Makusanyo
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Inaweza kusakinishwa bila Administrator (kwa mtumiaji mmoja).
; Mtumiaji akitaka, anaweza kuchagua "kwa watumiaji wote".
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=output
OutputBaseFilename=Makusanyo-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Windows 10 na kuendelea, 64-bit (x64 na ARM64 kupitia emulation).
; Flutter haitumiki kwenye Windows 7/8 wala 32-bit.
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Funga app kama inaendelea kufanya kazi wakati wa kusasisha (update).
CloseApplications=yes
RestartApplications=no

[Files]
; Inajumuisha DLL za Visual C++ (app-local), ili PC safi zisihitaji kusakinisha VC++ Redistributable.
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Fungua app sasa"; Flags: nowait postinstall skipifsilent
