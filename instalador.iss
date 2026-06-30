[Setup]
AppName=Software Petroglifos
AppVersion=1.0
DefaultDirName={autopf}\Software Petroglifos
DefaultGroupName=Software Petroglifos

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Software Petroglifos"; Filename: "{app}\software_petroglifos.exe"
Name: "{autodesktop}\Software Petroglifos"; Filename: "{app}\software_petroglifos.exe"
OutputBaseFilename=Software_Petroglifos_v1.0