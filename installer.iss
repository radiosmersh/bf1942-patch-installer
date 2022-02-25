#define MyAppName "Battlefield 1942 Master Server Patch"
#define MyAppVersion "1.0"

[Setup]
AppId={{84CDC31D-1CEE-4367-859E-A53F702B519B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName=no
AllowNoIcons=yes
DisableReadyPage=yes
DisableDirPage=yes
PrivilegesRequired=admin
Compression=lzma2/max
OutputBaseFilename=bf1942_patch
SetupIconFile=gfx\bf1942.ico
InfoBeforeFile=infobefore.txt
Uninstallable=No

[Files]
Source: "files\Retail\BF1942.exe"; DestDir: "{code:GetInstallPath}"; Check: IsRetailInstalled
Source: "files\Origin\BF1942.exe"; DestDir: "{code:GetInstallPath}"; Check: not IsRetailInstalled

[Registry]
Root: HKLM32; Subkey: "Software\EA GAMES\Battlefield 1942"; ValueType: string; ValueName: "GAMEDIR"; ValueData: "{code:GetInstallPath}"; Check: IsRetailInstalled; Flags: createvalueifdoesntexist
Root: HKLM32; Subkey: "Software\Origin\EA GAMES\Battlefield 1942"; ValueType: string; ValueName: "GAMEDIR"; ValueData: "{code:GetInstallPath}"; Check: not IsRetailInstalled; Flags: createvalueifdoesntexist

[Code]
{ WORKAROUND }
{ Checkboxes and Radio buttons created on runtime do }
{ not scale their height automatically. }
{ See https://stackoverflow.com/q/30469660/850848 }
procedure ScaleFixedHeightControl(Control: TButtonControl);
begin
  Control.Height := ScaleY(Control.Height);
end;

var
  InstallDirPage: TInputDirWizardPage;
  RetailVersionButton: TRadioButton;
  OriginVersionButton: TRadioButton;
  OldNextButtonOnClick: TNotifyEvent;
  OriginInstalled, RetailInstalled: Boolean;
  OriginPath, RetailPath: String;
  VersionTextLabel, DestDirTextLabel: TLabel;

function GetInstallPath(temp: String): String;
begin
  Result := InstallDirPage.Values[0];
end;

function IsRetailInstalled(): Boolean;
begin
  Result := RetailVersionButton.Checked;
end;

procedure SetPaths;
var
buff: String;
begin
  if RegQueryStringValue(HKLM32, 'Software\EA GAMES\Battlefield 1942', 'GAMEDIR', buff) then
    if DirExists(buff) and FileExists(buff + '\BF1942.exe') then
    begin
        RetailInstalled := true;
        RetailPath := buff;
    end;
  if RegQueryStringValue(HKLM32, 'Software\Origin\Battlefield 1942', 'GAMEDIR', buff) then
    if DirExists(buff) and FileExists(buff + '\BF1942.exe') then
      begin
          OriginInstalled := true;
          OriginPath := buff;
      end;
  if RetailInstalled then
      if OriginInstalled then
        begin
            MsgBox('Installations of both retail and Origin versions of Battlefield 1942 are detected, and the former was chosen as target directory. Please change it if needed.',
                    mbInformation, MB_OK);
            RetailVersionButton.Checked := True;
            InstallDirPage.Values[0] := RetailPath;
        end
      else
        begin
            RetailVersionButton.Checked := True;
            InstallDirPage.Values[0] := RetailPath;
        end
  else
      if OriginInstalled then
        begin
          OriginVersionButton.Checked := True;
          InstallDirPage.Values[0] := OriginPath;
        end
      else
        begin
          MsgBox('No Battlefield 1942 installations were found, a default installation location will be used.',
                 mbInformation, MB_OK);
          InstallDirPage.Values[0] := ExpandConstant('{pf32}') + '\EA Games\Battlefield 1942';
        end;
end;

procedure NextButtonOnClick(Sender: TObject);
var
  PrevDir: string;
begin
  if (WizardForm.CurPageID = InstallDirPage.ID) then
      if not RetailVersionButton.Checked and not OriginVersionButton.Checked then 
        begin
          MsgBox('Please select your game version.', mbInformation, MB_OK);
          exit;
        end
      else
        OldNextButtonOnClick(Sender)
  else
    OldNextButtonOnClick(Sender);
end;

procedure InitializeWizard();
var
buff: String;
begin
  InstallDirPage := CreateInputDirPage(wpSelectDir, 'Select Battlefield 1942 installation directory',
                                    'Where should the patch be installed?', '',
                                    False, 'Battlefield 1942');
  InstallDirPage.Add('');

  VersionTextLabel := TLabel.Create(WizardForm);
  VersionTextLabel.Parent := InstallDirPage.Surface;
  VersionTextLabel.Top := InstallDirPage.Edits[0].Top;
  VersionTextLabel.Caption := 'Select game version:';

  RetailVersionButton := TRadioButton.Create(WizardForm);
  RetailVersionButton.Parent := InstallDirPage.Surface;
  RetailVersionButton.Top := VersionTextLabel.Top + VersionTextLabel.Height + ScaleY(8);
  RetailVersionButton.Caption := 'v1.61 Retail';
  ScaleFixedHeightControl(RetailVersionButton);
  
  OriginVersionButton := TRadioButton.Create(WizardForm);
  OriginVersionButton.Parent := InstallDirPage.Surface;
  OriginVersionButton.Top := RetailVersionButton.Top + RetailVersionButton.Height + ScaleY(8);
  OriginVersionButton.Caption := 'v1.612 Origin';
  ScaleFixedHeightControl(RetailVersionButton);

  DestDirTextLabel := TLabel.Create(WizardForm);
  DestDirTextLabel.Parent := InstallDirPage.Surface;
  DestDirTextLabel.Top := OriginVersionButton.Top + OriginVersionButton.Height + ScaleY(8);
  DestDirTextLabel.Caption := 'Select installation dir:';

  InstallDirPage.Buttons[0].Top :=
    InstallDirPage.Buttons[0].Top +
    ((DestDirTextLabel.Top + DestDirTextLabel.Height + ScaleY(8)) -
      InstallDirPage.Edits[0].Top);
  InstallDirPage.Edits[0].Top :=
    DestDirTextLabel.Top + DestDirTextLabel.Height + ScaleY(8);
  InstallDirPage.Edits[0].Left := InstallDirPage.Edits[0].Left + ScaleX(16);
  InstallDirPage.Edits[0].Width := InstallDirPage.Edits[0].Width - ScaleX(16);
  InstallDirPage.Edits[0].TabOrder := OriginVersionButton.TabOrder + 1;
  InstallDirPage.Buttons[0].TabOrder := InstallDirPage.Edits[0].TabOrder + 1;

  SetPaths;

  OldNextButtonOnClick := WizardForm.NextButton.OnClick;
  WizardForm.NextButton.OnClick := @NextButtonOnClick;
end;
