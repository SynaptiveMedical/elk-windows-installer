; ELK (elasticsearch - kibana) windows installer nsis script
; Copyright (c) 2016 Luigi Grilli
;
; basic script template for NSIS installers
;
; Written by Philip Chu
; Copyright (c) 2004-2005 Technicat, LLC
;
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
 
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it ; and redistribute
; it freely, subject to the following restrictions:
 
;    1. The origin of this software must not be misrepresented; you must not claim that
;       you wrote the original software. If you use this software in a product, an
;       acknowledgment in the product documentation would be appreciated but is not required.
 
;    2. Altered source versions must be plainly marked as such, and must not be
;       misrepresented as being the original software.
 
;    3. This notice may not be removed or altered from any source distribution.

; Command line options for ElasticSearch
; /DATADIR= specify ElasticSearch data directory
; /LOGSDIR= specify ElasticSearch logs directory
; /REPODIR= specify ElasticSearch repository directory
 
; include for some of the windows messages defines
!include "winmessages.nsh"

!include MUI.nsh
!include Sections.nsh
!include LogicLib.nsh
!include "FileFunc.nsh"
!include "x64.nsh"

; HKLM (all users) vs HKCU (current user) defines
!define env_hklm 'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
!define env_hkcu 'HKCU "Environment"'

;version is passed as a parameter during makensis invocation
!define setup "dist\elk-x64-${version}-OpenJDKfriendly.exe"
 
; change this to wherever the files to be packaged reside
!define srcdir "temp"
 
!define company "Elasticsearch"
 
!define prodname "ELK"
 
; optional stuff
 
; Set the text which prompts the user to enter the installation directory
; DirText "My Description Here."
 
; text file to open in notepad after installation
!define notefile "elasticsearch\README.textile"
 
; license text file
!define licensefile elasticsearch\license.txt
 
; icons must be Microsoft .ICO files
; !define icon "icon.ico"
 
; installer background screen
; !define screenimage background.bmp
 
; file containing list of file-installation commands
; !define files "files.nsi"
 
; file containing list of file-uninstall commands
; !define unfiles "unfiles.nsi"
 
; registry stuff
 
!define regkey "Software\${company}\${prodname}"
!define uninstkey "Software\Microsoft\Windows\CurrentVersion\Uninstall\${prodname}"
 
!define startmenu "$SMPROGRAMS\${company}\${prodname}"
!define uninstaller "uninstall.exe"

!define CONFIG_TOOL_PATH "$INSTDIR\configurationtool"

!define SNAPSHOT_REPO_NAME "AllSnapshots"

;-------------------------------- 
XPStyle on
ShowInstDetails hide
ShowUninstDetails hide
 
Name "${prodname}"
Caption "${prodname}"
 
!ifdef icon
Icon "${icon}"
!endif
 
OutFile "${setup}"
 
SetDateSave on
SetDatablockOptimize on
CRCCheck on
SilentInstall normal
 
InstallDir "C:\Elk"
InstallDirRegKey HKLM "${regkey}" ""
 
!ifdef licensefile
LicenseText "License"
LicenseData "${srcdir}\${licensefile}"
!endif

; pages
; we keep it simple - leave out selectable installation types
 
!ifdef licensefile
Page license
!endif
 
; Page components
Page components
Page directory
Page Custom PageElasticSearchConfigurationShow PageElasticSearchConfigurationLeave
Page instfiles
 
UninstPage uninstConfirm
UninstPage instfiles

ReserveFile "PageElasticSearchConfiguration.ini" 
;--------------------------------
 
AutoCloseWindow false
ShowInstDetails show

Var ElasticSearchDataDirectory
Var ElasticSearchLogsDirectory
Var ElasticSearchRepositoryDirectory

!macro PowerShellExecFile1Macro PSFile Params
    !define PSExecID ${__LINE__}
    ${If} ${RunningX64}
        ${DisableX64FSRedirection}
    ${EndIf}
    
	nsExec::ExecToStack 'powershell -noprofile -inputformat none -ExecutionPolicy RemoteSigned -File "${PSFile}" ${Params} '

    ${If} ${RunningX64}
        ${EnableX64FSRedirection}
    ${EndIf}   
    !undef PSExecID
!macroend

!define PowerShellExecFile1 `!insertmacro PowerShellExecFile1Macro`

Function .onInit
    Call GetCmdLineElasticConfiguration
FunctionEnd

!ifdef screenimage
 
; set up background image
; uses BgImage plugin

Function .onGUIInit
	; extract background BMP into temp plugin directory
	InitPluginsDir
	File /oname=$PLUGINSDIR\1.bmp "${screenimage}"
 
	BgImage::SetBg /NOUNLOAD /FILLSCREEN $PLUGINSDIR\1.bmp
	BgImage::Redraw /NOUNLOAD
FunctionEnd
 
Function .onGUIEnd
	; Destroy must not have /NOUNLOAD so NSIS will be able to unload and delete BgImage before it exits
	BgImage::Destroy
FunctionEnd
 
!endif

; ---- ConfigureElasticSearch ----
Function GetCmdLineElasticConfiguration
	
	Push $R0

	DetailPrint "Setting Initial ElasticSearch Configuration Values"
	
	${GetParameters} $R0
	
	${GetOptions} $R0 /DATADIR= $ElasticSearchDataDirectory
	${If} $ElasticSearchDataDirectory == ''
        StrCpy $ElasticSearchDataDirectory '$INSTDIR/elasticsearch/data'
    ${EndIf}
	
	${GetOptions} $R0 /LOGSDIR= $ElasticSearchLogsDirectory
    ${If} $ElasticSearchLogsDirectory == ''
        StrCpy $ElasticSearchLogsDirectory '$INSTDIR/elasticsearch/logs'
    ${EndIf}
	
	${GetOptions} $R0 /REPODIR= $ElasticSearchRepositoryDirectory
    ${If} $ElasticSearchRepositoryDirectory == ''
        StrCpy $ElasticSearchRepositoryDirectory '$INSTDIR/elasticsearch/${SNAPSHOT_REPO_NAME}'
    ${EndIf}

FunctionEnd

Function PageElasticSearchConfigurationShow
	${Unless} ${SectionIsSelected} "Elasticsearch"
		Abort
	${EndUnless}
	
	SetOutPath $INSTDIR
	
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT_AS "PageElasticSearchConfiguration.ini" "PageElasticSearchConfiguration.ini"
    !insertmacro MUI_HEADER_TEXT "$(PageElasticSearch_TITLE)" "$(PageElasticSearch_SUBTITLE)"
	!insertmacro MUI_INSTALLOPTIONS_WRITE "PageElasticSearchConfiguration.ini" "Field 8" "State" $ElasticSearchDataDirectory
	!insertmacro MUI_INSTALLOPTIONS_WRITE "PageElasticSearchConfiguration.ini" "Field 10" "State" $ElasticSearchLogsDirectory
	!insertmacro MUI_INSTALLOPTIONS_WRITE "PageElasticSearchConfiguration.ini" "Field 12" "State" $ElasticSearchRepositoryDirectory
    !insertmacro MUI_INSTALLOPTIONS_DISPLAY "PageElasticSearchConfiguration.ini"
FunctionEnd

Function PageElasticSearchConfigurationLeave
	!insertmacro MUI_INSTALLOPTIONS_READ $ElasticSearchDataDirectory "PageElasticSearchConfiguration.ini" "Field 8" "State"
	!insertmacro MUI_INSTALLOPTIONS_READ $ElasticSearchLogsDirectory "PageElasticSearchConfiguration.ini" "Field 10" "State"
	!insertmacro MUI_INSTALLOPTIONS_READ $ElasticSearchRepositoryDirectory "PageElasticSearchConfiguration.ini" "Field 12" "State"
FunctionEnd

Function ConfigureElasticSearch
	Push $R0
	Push $R1

	DetailPrint "--- Configuring ElasticSearch"
	
	DetailPrint "ConfigFilePath '$INSTDIR\elasticsearch\config\elasticsearch.yml'"
    DetailPrint "DataPath '$ElasticSearchDataDirectory'"
	DetailPrint "LogsPath '$ElasticSearchLogsDirectory'"
	DetailPrint "RepoPath '$ElasticSearchRepositoryDirectory'"
	DetailPrint "${CONFIG_TOOL_PATH}\ElasticSearchConfiguration.ps1 -ConfigFilePath '$INSTDIR\elasticsearch\config\elasticsearch.yml' -DataPath '$ElasticSearchDataDirectory' -LogsPath '$ElasticSearchLogsDirectory' -RepoPath '$ElasticSearchRepositoryDirectory'"
	${PowerShellExecFile1} "${CONFIG_TOOL_PATH}\ElasticSearchConfiguration.ps1" '-ConfigFilePath "$INSTDIR\elasticsearch\config\elasticsearch.yml" -DataPath "$ElasticSearchDataDirectory" -LogsPath "$ElasticSearchLogsDirectory" -RepoPath "$ElasticSearchRepositoryDirectory"'
	Pop $R0
	Pop $R1
	DetailPrint "PowerShell Script returned: $R0"
	DetailPrint "PowerShell Script result:"
	DetailPrint "'$R1'"
	
	DetailPrint "--- Configuring ElasticSearch completed."		
	
FunctionEnd

Function ConfigureKibana
	Push $R0
	Push $R1

	DetailPrint "--- Configuring Kibana"
	
	DetailPrint "ConfigFilePath '$INSTDIR\kibana\config\kibana.yml'"
	DetailPrint "${CONFIG_TOOL_PATH}\KibanaConfiguration.ps1 -ConfigFilePath '$INSTDIR\kibana\config\kibana.yml'"
	${PowerShellExecFile1} "${CONFIG_TOOL_PATH}\KibanaConfiguration.ps1" '-ConfigFilePath "$INSTDIR\kibana\config\kibana.yml"'
	Pop $R0
	Pop $R1
	DetailPrint "PowerShell Script returned: $R0"
	DetailPrint "PowerShell Script result:"
	DetailPrint "'$R1'"
	
	DetailPrint "--- Configuring Kibana completed."		
	
FunctionEnd

; beginning (invisible) section
Section
  ;First look for AdoptOpenJDK
  ClearErrors
  SetRegView 64

  StrCpy $0 0
  loop:
    EnumRegKey $1 HKLM SOFTWARE\AdoptOpenJDK\JDK\ $0
    StrCmp $1 "" notFoundOpenJDK
    IntOp $0 $0 + 1
    ;Check if the first characters correspond to version 8
    StrCpy $2 $1 2 0
    StrCmp $2 "8." foundOpenJDK loop

  foundOpenJDK:
  ReadRegStr $2 HKLM "SOFTWARE\AdoptOpenJDK\JDK\$1\hotspot\MSI" "Path"
  DetailPrint "$2"

  IfErrors 0 NoAbort
    DetailPrint "Couldn't find AdoptOpenJDK v8 installed. Checking for Java SDK next." 

  notFoundOpenJDK:
  
  ;Look for JDK
  ClearErrors
  ReadRegStr $1 HKLM "SOFTWARE\JavaSoft\Java Development Kit" "CurrentVersion"
  ReadRegStr $2 HKLM "SOFTWARE\JavaSoft\Java Development Kit\$1" "JavaHome"
  DetailPrint "$1 $2"

  IfErrors 0 NoAbort
    MessageBox MB_OK "Couldn't find AdoptOpenJDK v8 or a Java Development Kit installed. Setup will exit now." 
    Quit

  NoAbort:
    DetailPrint "Found JDK in path $2"
    StrCpy $R0 "$2"
    System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("JAVA_HOME", R0).r0'

  ; set environment variable
  WriteRegExpandStr ${env_hklm} JAVA_HOME $R0
  ; make sure windows knows about the change
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000   

  WriteRegStr HKLM "${regkey}" "Install_Dir" "$INSTDIR"
  ; write uninstall strings
  WriteRegStr HKLM "${uninstkey}" "DisplayName" "${prodname} (remove only)"
  WriteRegStr HKLM "${uninstkey}" "UninstallString" '"$INSTDIR\${uninstaller}"'
 
!ifdef filetype
  WriteRegStr HKCR "${filetype}" "" "${prodname}"
!endif
 
!ifdef icon
  WriteRegStr HKCR "${prodname}\DefaultIcon" "" "$INSTDIR\${icon}"
!endif
 
  SetOutPath $INSTDIR
 
; package all files, recursively, preserving attributes
; assume files are in the correct places
 
!ifdef licensefile
  File /a "${srcdir}\${licensefile}"
!endif
 
!ifdef notefile
  File /a "${srcdir}\${notefile}"
!endif
 
!ifdef icon
  File /a "${srcdir}\${icon}"
!endif

  SetOutPath $INSTDIR\nssm
  File /r "tools\nssm\*"

  SetOutPath $INSTDIR\scripts
  File /r "scripts\*"
  
  CreateDirectory "${CONFIG_TOOL_PATH}"
  SetOutPath "${CONFIG_TOOL_PATH}"
  File ElasticSearchConfiguration.ps1
  File KibanaConfiguration.ps1

  WriteUninstaller "${uninstaller}"
SectionEnd

Section "Elasticsearch" Elasticsearch
  SetOutPath $INSTDIR\elasticsearch
  
  File /r "${srcdir}\elasticsearch\*"

  Call ConfigureElasticSearch

  ; install elasticsearch service
  ExecWait "$INSTDIR\elasticsearch\bin\elasticsearch-service.bat install" $0
  ; set service to start automatically (delayed)
  ExecWait "sc config elasticsearch-service-x64 start=delayed-auto" $0
  
  StrCpy $R0 "$INSTDIR"
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("INSTDIR", R0).r0'
  StrCpy $R0 "$INSTDIR\nssm\win64\nssm.exe"
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("NSSM", R0).r0'
  
  ; start services
  ExecWait "net start elasticsearch-service-x64" $0
SectionEnd

Section "Kibana" Kibana
  SetOutPath $INSTDIR\kibana
  File /r "${srcdir}\kibana\*"

  Call ConfigureKibana

  ExecWait "$INSTDIR\scripts\kibana-install.bat" $0
  ExecWait "net start kibana" $0
SectionEnd


; Uninstaller
; All section names prefixed by "Un" will be in the uninstaller
 
UninstallText "This will uninstall ${prodname}."
 
!ifdef icon
UninstallIcon "${icon}"
!endif
 
Section "Uninstall"

  ; stop services
  ExecWait "net stop kibana"  
  ExecWait "net stop elasticsearch-service-x64"

  StrCpy $R0 "$INSTDIR"
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("INSTDIR", R0).r0'
  StrCpy $R0 "$INSTDIR\nssm\win64\nssm.exe"
  System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("NSSM", R0).r0'
    
  ExecWait "$INSTDIR\scripts\kibana-uninstall.bat" $0

  ; uninstall elasticsearch service
  ExecWait "$INSTDIR\elasticsearch\bin\elasticsearch-service.bat remove"  

  DeleteRegKey HKLM "${uninstkey}"
  DeleteRegKey HKLM "${regkey}"
 
  RmDir /r "$INSTDIR"

SectionEnd
