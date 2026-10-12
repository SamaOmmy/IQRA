; Windows installer for the Flutter build of IQRA (per-user, no admin needed).
;   makensis /DSRC=<release folder> /DVERSION=3.0.0 /DOUT=<installer path> scripts\installer.nsi
!include "MUI2.nsh"

Name "IQRA"
OutFile "${OUT}"
InstallDir "$LOCALAPPDATA\Programs\IQRA"
InstallDirRegKey HKCU "Software\IQRA" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
BrandingText "IQRA ${VERSION}"

!define MUI_ICON "..\iqra_app\windows\runner\resources\app_icon.ico"
!define MUI_UNICON "..\iqra_app\windows\runner\resources\app_icon.ico"
!define MUI_FINISHPAGE_RUN "$INSTDIR\iqra.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Open IQRA"

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "IQRA"
  SetOutPath "$INSTDIR"
  File /r "${SRC}\*.*"
  WriteUninstaller "$INSTDIR\Uninstall IQRA.exe"
  CreateShortcut "$SMPROGRAMS\IQRA.lnk" "$INSTDIR\iqra.exe"
  CreateShortcut "$DESKTOP\IQRA.lnk" "$INSTDIR\iqra.exe"
  WriteRegStr HKCU "Software\IQRA" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\IQRA" "DisplayName" "IQRA"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\IQRA" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\IQRA" "Publisher" "Sama Ommy"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\IQRA" "DisplayIcon" "$INSTDIR\iqra.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\IQRA" "UninstallString" "$INSTDIR\Uninstall IQRA.exe"
SectionEnd

Section "Uninstall"
  Delete "$SMPROGRAMS\IQRA.lnk"
  Delete "$DESKTOP\IQRA.lnk"
  RMDir /r "$INSTDIR"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\IQRA"
  DeleteRegKey HKCU "Software\IQRA"
SectionEnd
