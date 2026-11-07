; ************************************************************************
; Parameters for calling this universal InnoSetup Script
; ************************************************************************
; App / Product Information
; ------------------------------------------------------------------------
; /DcsProductName="My Application"
; /DcsProductNameWithStageCode="My Application [BETA]"
; /DcsExeName="MyExecutable.exe"
; /DcsAppPublisher="My App Publisher"
; /DcsAppPublisherURL="https://www.mycompany.org/"
; /DcsOutputBaseFilename="Setup_MyApplication"
; ************************************************************************
; Build Target (for Installation Requirements)
; ------------------------------------------------------------------------
; one of the following
; /DcsBuildTargetWIN32 | /DcsBuildTargetWIN64 | /DcsBuildTargetARM64
; Note: InnoSetup 7 is required (SetupArchitecture, GetFileProductVersionString)
; - WIN32: 32-bit Setup (x86)
; - WIN64: 64-bit Setup (x64)
; - ARM64: depends on csMinVersion (there is no ARM64 Setup)
;          Windows on ARM runs Intel binaries via emulation:
;          Windows 10 on ARM can only emulate x86 (32-bit),
;          Windows 11 on ARM can also emulate x64 (64-bit).
;          csMinVersion below 10.0.22000 (Windows 10): 32-bit Setup (x86)
;          csMinVersion 10.0.22000 or higher (Windows 11): 64-bit Setup (x64)
; ------------------------------------------------------------------------
; Minimum Version of Windows (for Installation Requirements)
; ------------------------------------------------------------------------
; /DcsMinVersion="major.minor.build" (Windows version)
; Xojo 2025r1.1: Require Windows 10 Version 1903 (May 2019 Update)
; /DcsMinVersion="10.0.18362"
; Xojo 2024r4.2: Require Windows 8.1 with Update 1
; /DcsMinVersion="6.3.9600"
; ************************************************************************
; Enable CodeSigning using Azure Artifact Signing (or .pfx)
; Note: AAS here doesn't mean to support Azure Artifact Signing only.
;       The Parameter just enables that this .iss will use the
;       Signtool command, which we label "AAS" here.
;       So calling the .iss will need the CodeSign Script "AAS" defined.
;       And that might sign with either Azure Artifact Signing or .pfx
; ------------------------------------------------------------------------
; /DcsCodeSignAAS
;
; If CodeSigning is enabled: Set CodeSign Tool with label 'AAS'
; which does the actual codesigning (either with Azure Artifact
; Signing or a .pfx)
; "/SAAS=Z:/usr/local/bin/[aas|pfx]-codesign.bat $f"
; ************************************************************************


#ifndef csProductName
  #define csProductName "My Application"
#endif
#ifndef csProductNameWithStageCode
  #define csProductNameWithStageCode "My Application [BETA]"
#endif
#ifndef csExeName
  #define csExeName "MyExecutable.exe"
#endif
#ifndef csAppPublisher
  #define csAppPublisher "My App Publisher"
#endif
#ifndef csAppPublisherURL
  #define csAppPublisherURL "https://www.mycompany.org/"
#endif
#ifndef csOutputBaseFilename
  #define csOutputBaseFilename "Setup_MyApplication"
#endif
#ifndef csMinVersion
  #define csMinVersion "10.0.18362"
#endif

#define ApplicationVersion	GetFileProductVersionString(AddBackslash(SourcePath) + csExeName)


[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID from the menu.) 
AppId={#csProductName}
AppName={#csProductName}
AppVerName={#csProductNameWithStageCode} {#ApplicationVersion}
AppVersion={#ApplicationVersion}
AppPublisher={#csAppPublisher}
AppPublisherURL={#csAppPublisherURL}

WizardStyle=modern

; Installation Settings
; Note: Remove 'not arm64' if you want to allow WIN32 or WIN64 apps to run on Windows ARM
;       This example will only allow installing the ARM64 build on Windows ARM
#if defined(csBuildTargetWIN32)
; 32-bit Setup
  SetupArchitecture=x86
; never allow a WIN32 to be installed on ARM64
  ArchitecturesAllowed=not arm64
#elif defined(csBuildTargetWIN64)
; 64-bit Setup (runs on x64 Windows and on Windows 11 on ARM64)
  SetupArchitecture=x64
  ArchitecturesInstallIn64BitMode=x64compatible
; if you want to prevent installing the WIN64 Intel Build on ARM64 (even if it works)
; ArchitecturesAllowed=x64compatible and not arm64
; allow installing the WIN64 Intel Build on ARM64
  ArchitecturesAllowed=x64compatible
#elif defined(csBuildTargetARM64)
; 64-bit Setup only if Windows 11 is required (Windows 10 on ARM can't emulate x64)
; Note: StrToVersion expects 4 components (else 10.0.22000 is parsed as 10.0.0.22000)
#if StrToVersion(csMinVersion + ".0") >= StrToVersion("10.0.22000.0")
  SetupArchitecture=x64
#else
  SetupArchitecture=x86
#endif
; require ARM64 - the application won't run on Intel
  ArchitecturesInstallIn64BitMode=arm64
  ArchitecturesAllowed=arm64
#endif

DefaultDirName={autopf}\{#csProductName}
;since no icons will be created in "{group}", we don't need the wizard to ask for a group name:
DefaultGroupName=
DisableProgramGroupPage=yes

SourceDir={#sourcepath}
OutputDir=.  
OutputBaseFilename={#csOutputBaseFilename}

Compression=lzma
SolidCompression=yes
ChangesAssociations=yes

MinVersion={#csMinVersion}

; Set Signtool only if called with Parameter /DcsCodeSignAAS
#ifdef csCodeSignAAS
  Signtool=AAS
#endif
; We don't set SignedUninstaller, but use it's Default value: yes if a SignTool is set, no otherwise
; SignedUninstaller=yes

UninstallDisplayIcon={app}\{#csExeName}


[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "*"; DestDir: "{app}"; Flags: overwritereadonly recursesubdirs uninsremovereadonly createallsubdirs ignoreversion

[Icons]
Name: "{commondesktop}\{#csProductName}"; Filename: "{app}\{#csExeName}"; Tasks: desktopicon
Name: "{commonprograms}\{#csProductName}"; Filename: "{app}\{#csExeName}"

[Run]
Filename: "{app}\{#csExeName}"; Description: "{cm:LaunchProgram,{#csProductName}}"; Flags: nowait postinstall skipifsilent
