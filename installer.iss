#define MyAppName "Battlefield 1942 Master Server Patch"
#define MyAppVersion "1.0"

[Setup]
AppId={{84CDC31D-1CEE-4367-859E-A53F702B519B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AllowNoIcons=yes
CreateAppDir=No
DisableDirPage=yes
DisableReadyPage=yes
Uninstallable=No
InfoBeforeFile=infobefore.txt
PrivilegesRequired=admin
OutputDir=dist
OutputBaseFilename=bf1942_patch
SetupIconFile=gfx\bf1942.ico
Compression=lzma2/max
SolidCompression=yes

[Files]
Source: {code:GetInstallPath}\BF1942.exe; DestDir: {code:GetInstallPath}; DestName: BF1942.exe.bak; Flags: external skipifsourcedoesntexist;
Source: files\Retail\BF1942.exe; DestDir: {code:GetInstallPath}; Flags: ignoreversion onlyifdestfileexists restartreplace; Check: IsRetailBtnChecked
Source: files\Retail\Mod.dll; DestDir: {code:GetInstallPath}\Mods\bf1942; Flags: ignoreversion onlyifdestfileexists restartreplace; Check: IsRetailBtnChecked
Source: files\Retail\Mod.dll; DestDir: {code:GetInstallPath}\Mods\Xpack1; Flags: ignoreversion onlyifdestfileexists restartreplace; Check: IsRetailBtnChecked
Source: files\Retail\Mod.dll; DestDir: {code:GetInstallPath}\Mods\Xpack2; Flags: ignoreversion onlyifdestfileexists restartreplace; Check: IsRetailBtnChecked
Source: files\Retail\contentCrc32.con; DestDir: {code:GetInstallPath}\Mods\bf1942; Flags: ignoreversion; Check: IsRetailBtnChecked
Source: files\Retail\Init.con; DestDir: {code:GetInstallPath}\Mods\bf1942; Flags: ignoreversion; Check: IsRetailBtnChecked
Source: files\Origin\BF1942.exe; DestDir: {code:GetInstallPath}; Flags: ignoreversion onlyifdestfileexists restartreplace; Check: IsOriginBtnChecked


[Registry]
Root: HKLM32; Subkey: SOFTWARE\Electronic Arts\EA Games\Battlefield 1942\ergc; ValueType: string; ValueData: {code:GenerateCDKey}; Check: IsRetailBtnChecked; Flags: createvalueifdoesntexist
Root: HKLM32; Subkey: SOFTWARE\Electronic Arts\Origin\Battlefield 1942\ergc; ValueType: String; ValueData: {code:GenerateCDKey}; Check: not IsRetailBtnChecked; Flags: createvalueifdoesntexist
Root: HKLM64; SubKey: SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers; ValueType: string; ValueName: {code:GetInstallPath}\BF1942.exe; ValueData: RUNASADMIN; MinVersion: 6.0; Check: IsInstalledInPF64
Root: HKLM32; SubKey: SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers; ValueType: string; ValueName: {code:GetInstallPath}\BF1942.exe; ValueData: RUNASADMIN; MinVersion: 6.0; Check: IsInstalledInPF32


[Code]
var
  InstallDirPage: TInputDirWizardPage;
  RetailVerButton: TRadioButton;
  OriginVerButton: TRadioButton;
  OldNextButtonOnClick: TNotifyEvent;
  OriginVerInstalled, RetailVerInstalled: Boolean;
  OriginPath, RetailPath: String;
  VersionTextLabel, DestDirTextLabel: TLabel;

{ WORKAROUND }
{ Checkboxes and Radio buttons created on runtime do }
{ not scale their height automatically. }
{ See https://stackoverflow.com/q/30469660/850848 }
procedure ScaleFixedSizeControl(Control: TButtonControl);
begin
  Control.Height := ScaleY(Control.Height);
  Control.Width := ScaleX(Control.Width);
end;

function GenerateCDKey(Param: String): String;
begin
	Result := GetDateTimeString('42yyyy/mm/dd1942hhnnss', '1', #0);
end;

function DefaultOriginPath(): String;
begin
  Result := ExpandConstant('{pf32}') + '\Origin Games\Battlefield 1942';
end;

function DefaultRetailPath(): String;
begin
  Result := ExpandConstant('{pf32}') + '\EA Games\Battlefield 1942';
end;

function GetInstallPath(temp: String): String;
begin
  Result := InstallDirPage.Values[0];
end;

function IsBF1942Path(path: String): Boolean;
begin
  Result := DirExists(path) and FileExists(path + '\BF1942.exe');
end;

function IsInstalledInPF64(): Boolean;
begin
  Result := IsWin64() and (Pos(Lowercase(ExpandConstant('{pf32}')), Lowercase(InstallDirPage.Values[0])) > 0);
end;

function IsInstalledInPF32(): Boolean;
begin
  Result := (not IsWin64()) and (Pos(Lowercase(ExpandConstant('{pf32}')), Lowercase(InstallDirPage.Values[0])) > 0);
end;

function IsRetailBtnChecked(): Boolean;
begin
  Result := RetailVerButton.Checked;
end;

function IsOriginBtnChecked(): Boolean;
begin
  Result := OriginVerButton.Checked;
end;

procedure SetPathsAndVersion;
var
buff: String;
begin
  if RegQueryStringValue(HKLM32, 'SOFTWARE\EA GAMES\Battlefield 1942', 'GAMEDIR', buff) then
    if IsBF1942Path(buff) then
    begin
        RetailVerInstalled := true;
        RetailPath := buff;
    end;
  if RegQueryStringValue(HKLM32, 'SOFTWARE\Origin\Battlefield 1942', 'GAMEDIR', buff) then
    if IsBF1942Path(buff) then
      begin
          OriginVerInstalled := true;
          OriginPath := buff;
      end;
  if RetailVerInstalled then
      if OriginVerInstalled then
        begin
            MsgBox('Installations of both retail and Origin versions of Battlefield 1942 are detected, and the former was chosen as target directory. Please change it if needed.',
                    mbInformation, MB_OK);
            RetailVerButton.Checked := True;
            InstallDirPage.Values[0] := RetailPath;
        end
      else
        begin
            RetailVerButton.Checked := True;
            InstallDirPage.Values[0] := RetailPath;
        end
  else
      if OriginVerInstalled then
        begin
          OriginVerButton.Checked := True;
          InstallDirPage.Values[0] := OriginPath;
        end
      else
        if RegQueryStringValue(HKLM32, 'SOFTWARE\Electronic Arts\EA GAMES\Battlefield 1942\ergc', '', buff) then
          begin
            RetailVerButton.Checked := True;
            InstallDirPage.Values[0] := DefaultRetailPath();
          end
        else if RegQueryStringValue(HKLM32, 'SOFTWARE\Electronic Arts\Origin\Battlefield 1942\ergc', '', buff) then
          begin
            OriginVerButton.Checked := True;
            InstallDirPage.Values[0] := DefaultOriginPath();
          end
        else
          begin
            MsgBox('No Battlefield 1942 installations were found, a default location will be used.',
                  mbInformation, MB_OK);
            InstallDirPage.Values[0] := ExpandConstant('{pf32}') + '\EA Games\Battlefield 1942';
          end;
end;

procedure NextButtonOnClick(Sender: TObject);
begin
  if (WizardForm.CurPageID = InstallDirPage.ID) then
    begin
      if not RetailVerButton.Checked and not OriginVerButton.Checked then 
        begin
          MsgBox('Select the version of the game:', mbInformation, MB_OK);
          Exit;
        end;
      if not IsBF1942Path(InstallDirPage.Values[0]) then
        begin
          MsgBox('Selected destination folder is not a valid game directory.', mbInformation, MB_OK);
          Exit;
        end;
    end;
  OldNextButtonOnClick(Sender);
end;

procedure OriginVerButtonOnClick(Sender: TObject);
begin
  if OriginVerInstalled then
    InstallDirPage.Values[0] := OriginPath
  else if (InstallDirPage.Values[0] = DefaultRetailPath())
    or (InstallDirPage.Values[0] = '') then
    begin
      InstallDirPage.Values[0] := DefaultOriginPath();
    end;
end;

procedure RetailVerButtonOnClick(Sender: TObject);
begin
  if RetailVerInstalled then
    InstallDirPage.Values[0] := RetailPath
  else if (InstallDirPage.Values[0] = DefaultOriginPath())
    or (InstallDirPage.Values[0] = '') then
    begin
      InstallDirPage.Values[0] := DefaultRetailPath();
    end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = InstallDirPage.ID then
     SetPathsAndVersion;
end;

procedure InitializeWizard();
begin
  InstallDirPage := CreateInputDirPage(wpSelectDir, 'Select Battlefield 1942 installation directory',
                                    'Where should the patch be installed?', '',
                                    False, 'Battlefield 1942');
  InstallDirPage.Add('');

  VersionTextLabel := TLabel.Create(WizardForm);
  VersionTextLabel.Parent := InstallDirPage.Surface;
  VersionTextLabel.Top := InstallDirPage.Edits[0].Top;
  VersionTextLabel.Caption := 'Select game version:';

  RetailVerButton := TRadioButton.Create(WizardForm);
  RetailVerButton.Parent := InstallDirPage.Surface;
  RetailVerButton.Top := VersionTextLabel.Top + VersionTextLabel.Height + ScaleY(8);
  RetailVerButton.Caption := 'Retail';
  ScaleFixedSizeControl(RetailVerButton);
  
  OriginVerButton := TRadioButton.Create(WizardForm);
  OriginVerButton.Parent := InstallDirPage.Surface;
  OriginVerButton.Top := RetailVerButton.Top + RetailVerButton.Height;
  OriginVerButton.Caption := 'Origin';
  ScaleFixedSizeControl(OriginVerButton);

  DestDirTextLabel := TLabel.Create(WizardForm);
  DestDirTextLabel.Parent := InstallDirPage.Surface;
  DestDirTextLabel.Top := OriginVerButton.Top + OriginVerButton.Height + ScaleY(8);
  DestDirTextLabel.Caption := 'Select installation dir:';

  InstallDirPage.Buttons[0].Top :=
    InstallDirPage.Buttons[0].Top +
    ((DestDirTextLabel.Top + DestDirTextLabel.Height + ScaleY(8)) -
      InstallDirPage.Edits[0].Top);
  InstallDirPage.Edits[0].Top :=
    DestDirTextLabel.Top + DestDirTextLabel.Height + ScaleY(8);
  InstallDirPage.Edits[0].Left := InstallDirPage.Edits[0].Left + ScaleX(16);
  InstallDirPage.Edits[0].Width := InstallDirPage.Edits[0].Width - ScaleX(16);
  InstallDirPage.Edits[0].TabOrder := OriginVerButton.TabOrder + 1;
  InstallDirPage.Buttons[0].TabOrder := InstallDirPage.Edits[0].TabOrder + 1;

  RetailVerButton.OnClick := @RetailVerButtonOnClick;
  OriginVerButton.OnClick := @OriginVerButtonOnClick;

  OldNextButtonOnClick := WizardForm.NextButton.OnClick;
  WizardForm.NextButton.OnClick := @NextButtonOnClick;
end;
