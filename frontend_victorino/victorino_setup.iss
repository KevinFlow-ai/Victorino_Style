; =============================================================================
;  Victorino Style — Script de instalador para Windows (Inno Setup 6)
;  Genera: VictorinoStyle_Setup_1.0.0.exe
;
;  Para compilar este script:
;    1. Abre Inno Setup Compiler
;    2. Abre este archivo .iss
;    3. Pulsa Ctrl+F9 (Build)
;  O desde línea de comandos:
;    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" victorino_setup.iss
; =============================================================================

#define AppName      "Victorino Style"
#define AppVersion   "1.0.0"
#define AppPublisher "Victorino Style"
#define AppExeName   "frontend_victorino.exe"
#define SourceDir    "build\windows\x64\runner\Release"

[Setup]
; Identificador único de la aplicación (NO cambiar entre versiones para que el
; desinstalador pueda detectar instalaciones previas).
AppId={{A3F2B7C1-9E4D-4F8A-B2E6-7D1C3F5A9B8E}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisherURL=https://victorino-style.es
AppSupportURL=https://victorino-style.es
AppUpdatesURL=https://victorino-style.es
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
; Carpeta donde se guardará el .exe instalador resultante
OutputDir=instalador_windows
OutputBaseFilename=VictorinoStyle_Setup_{#AppVersion}
; Icono del installer (.ico generado por Flutter en la carpeta windows)
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
; Requiere Windows 10 o superior (igual que el proyecto Flutter)
MinVersion=10.0
; El instalador pide elevación de administrador para instalar en Program Files
PrivilegesRequired=admin

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear un icono en el &escritorio"; GroupDescription: "Iconos adicionales:"; Flags: unchecked

[Files]
; Copia todos los archivos de la carpeta Release, incluyendo subcarpetas (data/, etc.)
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Acceso directo en el menú Inicio
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
; Acceso directo para desinstalar en el menú Inicio
Name: "{group}\Desinstalar {#AppName}"; Filename: "{uninstallexe}"
; Acceso directo en el escritorio (solo si el usuario marcó la casilla)
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
; Ofrece lanzar la app al terminar la instalación
Filename: "{app}\{#AppExeName}"; Description: "Iniciar {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Limpia la carpeta completa al desinstalar
Type: filesandordirs; Name: "{app}"


