#tag BuildAutomation
			Begin BuildStepList Linux
				Begin BuildProjectStep Build
				End
			End
			Begin BuildStepList Mac OS X
				Begin BuildProjectStep Build
				End
				Begin SignProjectStep Sign
				  DeveloperID=
				  macOSEntitlements={"App Sandbox":"False","Hardened Runtime":"False","Notarize":"False","UserEntitlements":""}
				End
			End
			Begin BuildStepList Windows
				Begin BuildProjectStep Build
				End
				Begin IDEScriptBuildStep CodeSign , AppliesTo = 2, Architecture = 0, Target = 0
					'*********************************************************************************************
					' CodeSign | Azure Artifact Signing | PFX | Docker
					'*********************************************************************************************
					' https://github.com/jo-tools/aas-codesign-innosetup
					'*********************************************************************************************
					' Requirements
					'*********************************************************************************************
					' 1.  Set up Codesigning with one of the following
					' 1.1 Azure Artifact Signing
					'     Requires acs.json and azure.json in ~/.aas-codesign
					'     Strongly recommends aas-codesign-credential.sh in ~/.aas-codesign
					' 1.2 CodeSign Certificate .pfx
					'     Requires pfx.json and certificate.pfx in ~/.pfx-codesign
					'     Strongly recommends pfx-codesign-credential.sh in ~/.pfx-codesign
					' 2.  Have Docker up and running
					' 3.  Read the comments in this Post Build Script
					' 4.  Modify it according to your needs
					'
					'     Especially look out for sDOCKER_EXE
					'     You might need to set the full path to the executable
					'*********************************************************************************************
					' 5.  If it's working for you:
					'     Do you like it? Does it help you? Has it saved you time and money?
					'     You're welcome - it's free...
					'     If you want to say thanks I appreciate a message or a small donation.
					'     Contact: xojo@jo-tools.ch
					'     PayPal:  https://paypal.me/jotools
					'*********************************************************************************************
					
					'*********************************************************************************************
					' Note: Xojo IDE running on Linux
					'*********************************************************************************************
					' Make sure that docker can be run without requiring 'sudo':
					' More information e.g. in this article:
					' https://medium.com/devops-technical-notes-and-manuals/how-to-run-docker-commands-without-sudo-28019814198f
					' 1. sudo groupadd docker
					' 2. sudo gpasswd -a $USER docker
					' 3. (reboot)
					'*********************************************************************************************
					
					'*********************************************************************************************
					' Security Warning
					'*********************************************************************************************
					' This Post Build Script is intended as an example to demonstrate the functionality.
					' It allows to retrieve sensitive information (such as a Client Secret or Certificate
					' Password) from a plaintext `.json` configuration file, which is not secure.
					' However, this Post Build Script also supports retrieving credentials from a
					' Secret Storage. It's highly recommended to use that approach.
					'*********************************************************************************************
					
					
					If DebugBuild Then Return 'don't CodeSign DebugRun's
					
					'bSILENT=True : don't show any messages until checking configuration
					'               once .json required files are found: expect Docker and codesign to work
					'               use this e.g. in Open Source projects so that your builds will be codesigned,
					'               but if others are building the project it won't show messages to them
					Var bSILENT As Boolean = False 'in this example project we want to show if it's not going to work
					
					'Check Build Target
					Select Case CurrentBuildTarget
					Case 3  'Windows (Intel, 32Bit)
					Case 19 'Windows (Intel, 64Bit)
					Case 25 'Windows(ARM, 64Bit)
					Else
					If (Not bSILENT) Then Print "Codesign: Unsupported Build Target"
					Return
					End Select
					
					'Don't CodeSign Development and Alpha Builds
					Select Case PropertyValue("App.StageCode")
					Case "0" 'Development
					If (Not bSILENT) Then Print "Codesign: Not enabled for Development Builds"
					Return
					Case "1" 'Alpha
					If (Not bSILENT) Then Print "Codesign: Not enabled for Alpha Builds"
					Return
					Case "2" 'Beta
					Case "3" 'Final
					End Select
					
					'Configure what to be CodeSigned
					Var sSIGN_FILES() As String
					
					Select Case PropertyValue("App.StageCode")
					Case "3" 'Final
					' sign all .exe's and all .dll's
					sSIGN_FILES.Add("""./**/*.exe""") 'recursively all .exe's
					sSIGN_FILES.Add("""./**/*.dll""") 'recursively all .dll's
					Else
					' only sign all .exe's for Beta/Alpha/Development builds
					sSIGN_FILES.Add("""./**/*.exe""") 'recursively all .exe's
					End Select
					
					'Note: In your project use jotools/codesign if you are not using the InnoSetup Build Step.
					'      It's a smaller Docker Image...
					'      Should your project use the Post Build Script 'InnoSetup' too, then change here to use jotools/innosetup.
					'      InnoSetup includes codesign, too. So you don't need having two different Docker Images taking up space on your machine.
					Var sDOCKER_IMAGE As String = "jotools/codesign" 'or: "jotools/innosetup"
					
					Var sFILE_ACS_JSON As String = "" 'will be searched in ~/.aas-codesign
					Var sFILE_AZURE_JSON As String = "" 'will be searched in ~/.aas-codesign
					Var sFILE_PFX_JSON As String = "" 'will be searched in ~/.pfx-codesign
					Var sFILE_PFX_CERTIFICATE As String = "" 'will be searched in ~/.pfx-codesign
					Var sBUILD_LOCATION As String = CurrentBuildLocation
					
					'Check Environment
					Var sDOCKER_EXE As String = "docker"
					If TargetWindows Then 'Xojo IDE is running on Windows
					sFILE_ACS_JSON = DoShellCommand("if exist %USERPROFILE%\.aas-codesign\acs.json echo %USERPROFILE%\.aas-codesign\acs.json").Trim
					sFILE_AZURE_JSON = DoShellCommand("if exist %USERPROFILE%\.aas-codesign\azure.json echo %USERPROFILE%\.aas-codesign\azure.json").Trim
					sFILE_PFX_JSON = DoShellCommand("if exist %USERPROFILE%\.pfx-codesign\pfx.json echo %USERPROFILE%\.pfx-codesign\pfx.json").Trim
					sFILE_PFX_CERTIFICATE = DoShellCommand("if exist %USERPROFILE%\.pfx-codesign\certificate.pfx echo %USERPROFILE%\.pfx-codesign\certificate.pfx").Trim
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					sDOCKER_EXE = DoShellCommand("[ -f /usr/local/bin/docker ] && echo /usr/local/bin/docker").Trim
					If (sDOCKER_EXE = "") Then sDOCKER_EXE = DoShellCommand("[ -f /snap/bin/docker ] && echo /snap/bin/docker").Trim
					sFILE_ACS_JSON = DoShellCommand("[ -f ~/.aas-codesign/acs.json ] && echo ~/.aas-codesign/acs.json").Trim
					sFILE_AZURE_JSON = DoShellCommand("[ -f ~/.aas-codesign/azure.json ] && echo ~/.aas-codesign/azure.json").Trim
					sBUILD_LOCATION = sBUILD_LOCATION.ReplaceAll("\", "") 'don't escape Path
					sFILE_PFX_JSON = DoShellCommand("[ -f ~/.pfx-codesign/pfx.json ] && echo ~/.pfx-codesign/pfx.json").Trim
					sFILE_PFX_CERTIFICATE = DoShellCommand("[ -f ~/.pfx-codesign/certificate.pfx ] && echo ~/.pfx-codesign/certificate.pfx").Trim
					Else
					If (Not bSILENT) Then Print "Codesign: Xojo IDE running on unknown Target"
					Return
					End If
					
					Var bCODESIGN_AAS As Boolean = (sFILE_ACS_JSON <> "") And (sFILE_AZURE_JSON <> "")
					Var bCODESIGN_PFX As Boolean = (sFILE_PFX_JSON <> "") And (sFILE_PFX_CERTIFICATE <> "")
					
					If (Not bCODESIGN_AAS) And (Not bCODESIGN_PFX) Then
					If (Not bSILENT) Then
					Print "Codesign:" + EndOfLine + _
					"acs.json and azure.json not found in [UserHome]-[.aas-codesign]-[acs|azure.json]" + EndOfLine + _
					"pfx.json and certificate.pfx not found in [UserHome]-[.pfx-codesign]-[pfx.json|certificate.pfx]"
					End If
					Return
					End If
					
					'Check Docker
					Var iCHECK_DOCKER_RESULT As Integer
					Var sCHECK_DOCKER_EXE As String = DoShellCommand(sDOCKER_EXE + " --version", 0, iCHECK_DOCKER_RESULT).Trim
					If (iCHECK_DOCKER_RESULT <> 0) Or (Not sCHECK_DOCKER_EXE.Contains("Docker")) Or (Not sCHECK_DOCKER_EXE.Contains("version")) Or (Not sCHECK_DOCKER_EXE.Contains("build "))Then
					Print "Codesign: Docker not available"
					Return
					End If
					
					Var sCHECK_DOCKER_PROCESS As String = DoShellCommand(sDOCKER_EXE + " ps", 0, iCHECK_DOCKER_RESULT).Trim
					If (iCHECK_DOCKER_RESULT <> 0) Then
					Print "Codesign: Docker not running"
					Return
					End If
					
					'Get Credential from Secure Storage
					Var bENV_AAS_CREDENTIAL As Boolean
					Var bENV_PFX_CREDENTIAL As Boolean
					
					If bCODESIGN_AAS Or bCODESIGN_PFX Then
					Var SFILE_CREDENTIAL As String
					Var sCREDENTIAL_COMMAND As String
					
					If TargetWindows Then 'Xojo IDE is running on Windows
					If bCODESIGN_AAS Then
					SFILE_CREDENTIAL = DoShellCommand("if exist %USERPROFILE%\.aas-codesign\aas-codesign-credential.ps1 echo %USERPROFILE%\.aas-codesign\aas-codesign-credential.ps1").Trim
					ElseIf bCODESIGN_PFX Then
					SFILE_CREDENTIAL = DoShellCommand("if exist %USERPROFILE%\.pfx-codesign\pfx-codesign-credential.ps1 echo %USERPROFILE%\.pfx-codesign\pfx-codesign-credential.ps1").Trim
					End If
					If (SFILE_CREDENTIAL <> "") Then
					sCREDENTIAL_COMMAND = "powershell """ + SFILE_CREDENTIAL + """"
					End If
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					If bCODESIGN_AAS Then
					SFILE_CREDENTIAL = DoShellCommand("[ -f ~/.aas-codesign/aas-codesign-credential.sh ] && echo ~/.aas-codesign/aas-codesign-credential.sh").Trim
					ElseIf bCODESIGN_PFX Then
					SFILE_CREDENTIAL = DoShellCommand("[ -f ~/.pfx-codesign/pfx-codesign-credential.sh ] && echo ~/.pfx-codesign/pfx-codesign-credential.sh").Trim
					End If
					If (SFILE_CREDENTIAL <> "") Then
					Call DoShellCommand("chmod 755 """ + SFILE_CREDENTIAL + """") 'just to make sure it's executable
					sCREDENTIAL_COMMAND = SFILE_CREDENTIAL
					End If
					End If
					
					If (sCREDENTIAL_COMMAND <> "") Then
					'Once the Credential Helper Script is in place, we expect to get a value from it
					Var iCREDENTIAL_RESULT As Integer
					Var sCREDENTIAL As String = DoShellCommand(sCREDENTIAL_COMMAND, 0, iCREDENTIAL_RESULT).Trim
					If (iCREDENTIAL_RESULT <> 0) Or (sCREDENTIAL = "") Then
					Print  "Codesign: Could not retrieve " + If(bCODESIGN_AAS, "AAS", "PFX") + " Credential"
					Return
					End If
					
					'Use Environment Variable
					If bCODESIGN_AAS Then
					EnvironmentVariable("AZURE_CLIENT_SECRET") = sCREDENTIAL
					bENV_AAS_CREDENTIAL = true
					ElseIf bCODESIGN_PFX Then
					EnvironmentVariable("PFX_PASSWORD") = sCREDENTIAL
					bENV_PFX_CREDENTIAL = true
					End If
					End If
					End If
					
					'CodeSign in Docker Container
					Var sSIGN_COMMAND As String
					Var sSIGN_ENTRYPOINT As String
					If bCODESIGN_AAS Then
					'CodeSign using Azure Artifact Signing
					sSIGN_ENTRYPOINT = "aas-codesign.sh"
					sSIGN_COMMAND = _
					sDOCKER_EXE + " run " + _
					"--rm " + _
					"-v """ + sFILE_ACS_JSON + """:/etc/aas-codesign/acs.json " + _
					"-v """ + sFILE_AZURE_JSON + """:/etc/aas-codesign/azure.json " + _
					If(bENV_AAS_CREDENTIAL, "-e AZURE_CLIENT_SECRET ", "") + _
					"-v """ + sBUILD_LOCATION + """:/data " + _
					"-w /data " + _
					"--entrypoint " + sSIGN_ENTRYPOINT + " " + _
					sDOCKER_IMAGE + " " + _
					String.FromArray(sSIGN_FILES, " ")
					ElseIf bCODESIGN_PFX Then
					'CodeSign using .pfx
					sSIGN_ENTRYPOINT = "pfx-codesign.sh"
					sSIGN_COMMAND = _
					sDOCKER_EXE + " run " + _
					"--rm " + _
					"-v """ + sFILE_PFX_JSON + """:/etc/pfx-codesign/pfx.json " + _
					"-v """ + sFILE_PFX_CERTIFICATE + """:/etc/pfx-codesign/certificate.pfx " + _
					If(bENV_PFX_CREDENTIAL, "-e PFX_PASSWORD ", "") + _
					"-v """ + sBUILD_LOCATION + """:/data " + _
					"-w /data " + _
					"--entrypoint " + sSIGN_ENTRYPOINT + " " + _
					sDOCKER_IMAGE + " " + _
					String.FromArray(sSIGN_FILES, " ")
					End If
					
					Var iSIGN_RESULT As Integer
					Var sSIGN_OUTPUT As String = DoShellCommand(sSIGN_COMMAND, 0, iSIGN_RESULT)
					
					If (iSIGN_RESULT <> 0) Then
					If (iSIGN_RESULT <> 125) Then
					Var iCHECK_DOCKERIMAGE_RESULT As Integer
					Var sCHECK_DOCKERIMAGE_OUTPUT As String = DoShellCommand(sDOCKER_EXE + " image inspect " + sDOCKER_IMAGE, 0, iCHECK_DOCKERIMAGE_RESULT)
					If (iCHECK_DOCKERIMAGE_RESULT <> 0) Then
					Print "Codesign: Docker Image '" + sDOCKER_IMAGE + "' not available" + EndOfLine + EndOfLine + _
					"This sometimes occurs if Docker hasn't been able to automatically download the Docker Image when executing a 'docker run' command." + EndOfLine + EndOfLine + _
					"Download the required Docker Image once manually by executing this command in a Terminal Window:" + EndOfLine + _
					sDOCKER_EXE + " image pull " + sDOCKER_IMAGE
					Return
					End If
					End If
					
					Clipboard = sSIGN_OUTPUT
					Print "Codesign: " + sSIGN_ENTRYPOINT + " Error" + EndOfLine + _
					"[ExitCode: " + iSIGN_RESULT.ToString + "]" + EndOfLine + EndOfLine + _
					"Note: Shell Output is available in Clipboard."
					End If
					
				End
				Begin IDEScriptBuildStep CreateZIP , AppliesTo = 2, Architecture = 0, Target = 0
					'**************************************************
					' Create .zip for Windows Builds
					'**************************************************
					' https://github.com/jo-tools
					'**************************************************
					' 1. Read the comments in this PostBuild Script
					' 2. Edit the values according to your needs
					'**************************************************
					' 3. If it's working for you:
					'    Do you like it? Does it help you? Has it saved you time and money?
					'    You're welcome - it's free...
					'    If you want to say thanks I appreciate a message or a small donation.
					'    Contact: xojo@jo-tools.ch
					'    PayPal:  https://paypal.me/jotools
					'**************************************************
					
					If DebugBuild Then Return 'don't create .zip for DebugRuns
					
					'bSILENT=True : don't show any error messages
					Var bSILENT As Boolean = False
					
					'Check Build Target
					Select Case CurrentBuildTarget
					Case 3 'Windows (Intel, 32Bit)
					Case 19 'Windows (Intel, 64Bit)
					Case 25 'Windows(ARM, 64Bit)
					Else
					If (Not bSILENT) Then Print "CreateZIP: Unsupported Build Target"
					Return
					End Select
					
					'Xojo Project Settings
					Var sPROJECT_PATH As String
					Var sBUILD_LOCATION As String = CurrentBuildLocation
					Var sAPP_NAME As String = CurrentBuildAppName
					If (sAPP_NAME.Right(4) = ".exe") Then
					sAPP_NAME = sAPP_NAME.Left(sAPP_NAME.Length - 4)
					End If
					Var sCHAR_FOLDER_SEPARATOR As String
					If TargetWindows Then 'Xojo IDE is running on Windows
					sPROJECT_PATH = DoShellCommand("echo %PROJECT_PATH%", 0).Trim
					sCHAR_FOLDER_SEPARATOR = "\"
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					sPROJECT_PATH = DoShellCommand("echo $PROJECT_PATH", 0).Trim
					If sPROJECT_PATH.Right(1) = "/" Then
					'no trailing /
					sPROJECT_PATH = sPROJECT_PATH.Left(sPROJECT_PATH.Length - 1)
					End If
					If sBUILD_LOCATION.Right(1) = "/" Then
					'no trailing /
					sBUILD_LOCATION = sBUILD_LOCATION.Left(sBUILD_LOCATION.Length - 1)
					End If
					sBUILD_LOCATION = sBUILD_LOCATION.ReplaceAll("\", "") 'don't escape Path
					sCHAR_FOLDER_SEPARATOR = "/"
					End If
					
					If (sPROJECT_PATH = "") Then
					If (Not bSILENT) Then Print "CreateZIP: Could not get the Environment Variable PROJECT_PATH from the Xojo IDE." + EndOfLine + EndOfLine + "Unfortunately, it's empty.... try again after re-launching the Xojo IDE and/or rebooting your machine."
					Return
					End If
					
					'Check Stage Code for ZIP Filename
					Var sSTAGECODE_SUFFIX As String
					Select Case PropertyValue("App.StageCode")
					Case "0" 'Development
					sSTAGECODE_SUFFIX = "-dev"
					Case "1" 'Alpha
					sSTAGECODE_SUFFIX = "-alpha"
					Case "2" 'Beta
					sSTAGECODE_SUFFIX = "-beta"
					Case "3" 'Final
					'not used in filename
					End Select
					
					'Build ZIP Filename
					Var sZIP_FILENAME As String
					Select Case CurrentBuildTarget
					Case 3 'Windows (Intel, 32Bit)
					sZIP_FILENAME = sAPP_NAME.ReplaceAll(" ", "_") + sSTAGECODE_SUFFIX + "_Windows_Intel_32Bit.zip"
					Case 19 'Windows (Intel, 64Bit)
					sZIP_FILENAME = sAPP_NAME.ReplaceAll(" ", "_") + sSTAGECODE_SUFFIX + "_Windows_Intel_64Bit.zip"
					Case 25 'Windows(ARM, 64Bit)
					sZIP_FILENAME = sAPP_NAME.ReplaceAll(" ", "_") + sSTAGECODE_SUFFIX + "_Windows_ARM_64Bit.zip"
					Else
					Return
					End Select
					
					'Create .zip
					Var sPATH_PARTS() As String = sBUILD_LOCATION.Split(sCHAR_FOLDER_SEPARATOR)
					Var sAPP_FOLDERNAME As String = sPATH_PARTS(sPATH_PARTS.LastIndex)
					sPATH_PARTS.RemoveAt(sPATH_PARTS.LastIndex)
					Var sFOLDER_BASE As String = String.FromArray(sPATH_PARTS, sCHAR_FOLDER_SEPARATOR)
					
					If TargetWindows Then 'Xojo IDE is running on Windows
					Var sPOWERSHELL_COMMAND As String = "cd """ + sFOLDER_BASE + """; Compress-Archive -Path .\* -DestinationPath ""..\" + sZIP_FILENAME + """ -Force"
					Var iPOWERSHELL_RESULT As Integer
					Var sPOWERSHELL_OUTPUT As String = DoShellCommand("powershell -command """ + sPOWERSHELL_COMMAND.ReplaceAll("""", "'") + """", 0, iPOWERSHELL_RESULT)
					If (iPOWERSHELL_RESULT <> 0) Then
					If (Not bSILENT) Then Print "CreateZIP Error" + EndOfLine + EndOfLine + _
					sPOWERSHELL_OUTPUT.Trim + EndOfLine + _
					"[ExitCode: " + iPOWERSHELL_RESULT.ToString + "]"
					End If
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					Var iZIP_RESULT As Integer
					Var sZIP_OUTPUT As String = DoShellCommand("cd """ + sFOLDER_BASE + """ && zip -r ""../" + sZIP_FILENAME + """ ""./" + sAPP_FOLDERNAME + """", 0, iZIP_RESULT)
					If (iZIP_RESULT <> 0) Then
					If (Not bSILENT) Then Print "CreateZIP Error" + EndOfLine + EndOfLine + _
					sZIP_OUTPUT.Trim + EndOfLine + _
					"[ExitCode: " + iZIP_RESULT.ToString + "]"
					End If
					End If
					
				End
				Begin IDEScriptBuildStep InnoSetup , AppliesTo = 2, Architecture = 0, Target = 0
					'*********************************************************************************************
					' InnoSetup | Azure Artifact Signing | PFX | Docker
					'*********************************************************************************************
					' https://github.com/jo-tools/aas-codesign-innosetup
					'*********************************************************************************************
					' Requirements
					'*********************************************************************************************
					' 1.  Optional: Set up Codesigning with one of the following
					'     (only if you want a codesigned Installer)
					' 1.1 Azure Artifact Signing
					'     Requires acs.json and azure.json in ~/.aas-codesign
					'     Strongly recommends aas-codesign-credential.sh in ~/.aas-codesign
					' 1.2 CodeSign Certificate .pfx
					'     Requires pfx.json and certificate.pfx in ~/.pfx-codesign
					'     Strongly recommends pfx-codesign-credential.sh in ~/.pfx-codesign
					' 2.  Have Docker up and running
					' 3.  Put your own InnoSetup Script to the project location (or use the universal script
					'     provided with the example project - modify that according to your needs)
					' 4.  Read the comments in this Post Build Script
					' 5.  Modify it according to your needs
					'
					'     Especially look out for sDOCKER_EXE
					'     You might need to set the full path to the executable
					'
					'     Set bCODESIGN_ENABLED = False if you want to create a Windows Installer without
					'     CodeSigning. If this value is True, the Post Build Script will expect Codesigning to be
					'     available and print an Information Message if it's configuration is not found.
					'
					'     And at least change the sAPP_PUBLISHER_URL to your own Website if you're using
					'     the provided universal InnoSetup script
					'*********************************************************************************************
					' 6.  If it's working for you:
					'     Do you like it? Does it help you? Has it saved you time and money?
					'     You're welcome - it's free...
					'     If you want to say thanks I appreciate a message or a small donation.
					'     Contact: xojo@jo-tools.ch
					'     PayPal:  https://paypal.me/jotools
					'*********************************************************************************************
					
					'*********************************************************************************************
					' Note: Xojo IDE running on Linux
					'*********************************************************************************************
					' Make sure that docker can be run without requiring 'sudo':
					' More information e.g. in this article:
					' https://medium.com/devops-technical-notes-and-manuals/how-to-run-docker-commands-without-sudo-28019814198f
					' 1. sudo groupadd docker
					' 2. sudo gpasswd -a $USER docker
					' 3. (reboot)
					'*********************************************************************************************
					
					'*********************************************************************************************
					' Security Warning
					'*********************************************************************************************
					' This Post Build Script is intended as an example to demonstrate the functionality.
					' It allows to retrieve sensitive information (such as a Client Secret or Certificate
					' Password) from a plaintext `.json` configuration file, which is not secure.
					' However, this Post Build Script also supports retrieving credentials from a
					' Secret Storage. It's highly recommended to use that approach.
					'*********************************************************************************************
					
					
					If DebugBuild Then Return 'don't create a windows installer for DebugRun's
					
					'bCODESIGN_ENABLED: set this to False if you want to create a Windows Installer without CodeSigning
					Var bCODESIGN_ENABLED As Boolean = True 'when True this shows a Info when CodeSign Configuration is missing
					
					'bSILENT=True : don't show any messages until checking configuration
					Var bSILENT As Boolean = False 'in this example project we want to show if it's not going to work
					
					'bVERYSILENT=True : don't show any messages at all - even if Docker not Available or InnoSetup errors
					'                   use this e.g. in Open Source projects so that your builds will get an installer,
					'                   but if others are building the project it won't show messages to them if that fails
					Var bVERYSILENT As Boolean = False 'in this example project we want to show if it's not going to work
					
					'Sanity Check
					If bVERYSILENT Then bSILENT = True
					
					'Set InnoSetup Script
					'Note: This project includes a universal .iss script
					'      That's why we specify the same .iss for all WIN32, WIN64 and ARM64
					'Note: Folder Separator in this variable can be both \ or /
					Var sINNOSETUP_SCRIPT As String
					Select Case CurrentBuildTarget
					Case 3 'Windows (Intel, 32Bit)
					sINNOSETUP_SCRIPT = "_build/innosetup_universal.iss"
					Case 19 'Windows (Intel, 64Bit)
					sINNOSETUP_SCRIPT = "_build/innosetup_universal.iss"
					Case 25 'Windows(ARM, 64Bit)
					sINNOSETUP_SCRIPT = "_build/innosetup_universal.iss"
					Else
					If (Not bSILENT) Then Print "InnoSetup: Unsupported Build Target"
					Return
					End Select
					
					'Don't create Windows Installer for Development and Alpha Builds
					Select Case PropertyValue("App.StageCode")
					Case "0" 'Development
					If (Not bSILENT) Then Print "InnoSetup: Not enabled for Development Builds"
					Return
					Case "1" 'Alpha
					If (Not bSILENT) Then Print "InnoSetup: Not enabled for Alpha Builds"
					Return
					Case "2" 'Beta
					Case "3" 'Final
					End Select
					
					'Publisher Website
					Var sAPP_PUBLISHER_URL As String = "https://www.jo-tools.ch/"
					
					'****************************************************
					' Note: No more changes needed below here
					'****************************************************
					' This example includes a universal InnoSetup script.
					' All required information is being picked up from
					' the Xojo Project Settings.
					' Of course: feel free to change and modify it
					' according to your needs
					'****************************************************
					
					'Xojo Project Settings
					Var sBUILD_LOCATION As String = CurrentBuildLocation
					Var sAPP_EXE_BASEFILENAME As String = CurrentBuildAppName
					If (sAPP_EXE_BASEFILENAME.Right(4) = ".exe") Then
					sAPP_EXE_BASEFILENAME = sAPP_EXE_BASEFILENAME.Left(sAPP_EXE_BASEFILENAME.Length - 4)
					End If
					Var sAPP_PRODUCTNAME As String = PropertyValue("App.ProductName").Trim
					If (sAPP_PRODUCTNAME = "") Then
					If (Not bSILENT) Then
					Print "InnoSetup: App.ProductName is empty" + EndOfLine + EndOfLine + _
					"Set it in Xojo Build Settings: Windows"
					Return
					End If
					sAPP_PRODUCTNAME = sAPP_EXE_BASEFILENAME
					End If
					Var sAPP_COMPANYNAME As String = PropertyValue("App.CompanyName").Trim
					If (sAPP_COMPANYNAME = "") Then
					If (Not bSILENT) Then
					Print "InnoSetup: App.CompanyName is empty" + EndOfLine + EndOfLine + _
					"Set it in Xojo Build Settings: Windows"
					Return
					End If
					sAPP_COMPANYNAME = sAPP_EXE_BASEFILENAME
					End If
					
					'Check Stage Code for Application Version Name and Installer Filename
					Var sSTAGECODE_SUFFIX As String
					Var sAPP_PRODUCTNAME_STAGECODE_SUFFIX As String
					Select Case PropertyValue("App.StageCode")
					Case "0" 'Development
					sSTAGECODE_SUFFIX = "-dev"
					sAPP_PRODUCTNAME_STAGECODE_SUFFIX = "[Dev]"
					Case "1" 'Alpha
					sSTAGECODE_SUFFIX = "-alpha"
					sAPP_PRODUCTNAME_STAGECODE_SUFFIX = "[Alpha]"
					Case "2" 'Beta
					sSTAGECODE_SUFFIX = "-beta"
					sAPP_PRODUCTNAME_STAGECODE_SUFFIX = "[Beta]"
					Case "3" 'Final
					'not used in filename
					End Select
					
					'Build Installer Filename
					Var sSETUP_BASEFILENAME As String
					Select Case CurrentBuildTarget
					Case 3 'Windows (Intel, 32Bit)
					sSETUP_BASEFILENAME = sAPP_EXE_BASEFILENAME.ReplaceAll(" ", "_") + sSTAGECODE_SUFFIX + "_Setup_Intel_32Bit"
					Case 19 'Windows (Intel, 64Bit)
					sSETUP_BASEFILENAME = sAPP_EXE_BASEFILENAME.ReplaceAll(" ", "_") + sSTAGECODE_SUFFIX + "_Setup_Intel_64Bit"
					Case 25 'Windows(ARM, 64Bit)
					sSETUP_BASEFILENAME = sAPP_EXE_BASEFILENAME.ReplaceAll(" ", "_") + sSTAGECODE_SUFFIX + "_Setup_ARM_64Bit"
					Else
					Return
					End Select
					
					'System Requirements for built Windows application
					'Note: The universal InnoSetup Script creates a 32-bit installer for WIN32, a 64-bit installer for WIN64,
					'      and for ARM64 a 64-bit installer only if Windows 11 (10.0.22000) is required (otherwise 32-bit)
					Var sMINVERSION As String = "6.3.9600" 'Require Windows 8.1 with Update 1
					If (XojoVersion >= 2025.0) Then
					sMINVERSION = "10.0.18362" 'Require Windows 10 Version 1903 (May 2019 Update)
					End If
					
					'Set Parameters for InnoSetup Script
					Var sISS_csProductName As String = sAPP_PRODUCTNAME
					Var sISS_csProductNameWithStageCode As String = sAPP_PRODUCTNAME + " " + sAPP_PRODUCTNAME_STAGECODE_SUFFIX
					sISS_csProductNameWithStageCode = sISS_csProductNameWithStageCode.Trim 'Trim if no Suffix
					Var sISS_csExeName As String = sAPP_EXE_BASEFILENAME + ".exe" // we removed that before
					Var sISS_csAppPublisher As String = sAPP_COMPANYNAME
					Var sISS_csAppPublisherURL As String = sAPP_PUBLISHER_URL
					Var sISS_csOutputBaseFilename As String = sSETUP_BASEFILENAME
					
					'Variables for Docker
					Var sDOCKER_IMAGE As String = "jotools/innosetup"
					Var sFILE_ACS_JSON As String = "" 'will be searched in ~/.aas-codesign
					Var sFILE_AZURE_JSON As String = "" 'will be searched in ~/.aas-codesign
					Var sFILE_PFX_JSON As String = "" 'will be searched in ~/.pfx-codesign
					Var sFILE_PFX_CERTIFICATE As String = "" 'will be searched in ~/.pfx-codesign
					Var sPROJECT_PATH As String
					
					'Check Environment
					Var sDOCKER_EXE As String = "docker"
					Var sCHAR_FOLDER_SEPARATOR As String
					
					If TargetWindows Then 'Xojo IDE is running on Windows
					sPROJECT_PATH = DoShellCommand("echo %PROJECT_PATH%", 0).Trim
					sCHAR_FOLDER_SEPARATOR = "\"
					If bCODESIGN_ENABLED Then
					sFILE_ACS_JSON = DoShellCommand("if exist %USERPROFILE%\.aas-codesign\acs.json echo %USERPROFILE%\.aas-codesign\acs.json").Trim
					sFILE_AZURE_JSON = DoShellCommand("if exist %USERPROFILE%\.aas-codesign\azure.json echo %USERPROFILE%\.aas-codesign\azure.json").Trim
					sFILE_PFX_JSON = DoShellCommand("if exist %USERPROFILE%\.pfx-codesign\pfx.json echo %USERPROFILE%\.pfx-codesign\pfx.json").Trim
					sFILE_PFX_CERTIFICATE = DoShellCommand("if exist %USERPROFILE%\.pfx-codesign\certificate.pfx echo %USERPROFILE%\.pfx-codesign\certificate.pfx").Trim
					End If
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					sPROJECT_PATH = DoShellCommand("echo $PROJECT_PATH", 0).Trim
					If sPROJECT_PATH.Right(1) = "/" Then
					'no trailing /
					sPROJECT_PATH = sPROJECT_PATH.Left(sPROJECT_PATH.Length - 1)
					End If
					If sBUILD_LOCATION.Right(1) = "/" Then
					'no trailing /
					sBUILD_LOCATION = sBUILD_LOCATION.Left(sBUILD_LOCATION.Length - 1)
					End If
					sCHAR_FOLDER_SEPARATOR = "/"
					sBUILD_LOCATION = sBUILD_LOCATION.ReplaceAll("\", "") 'don't escape Path
					sDOCKER_EXE = DoShellCommand("[ -f /usr/local/bin/docker ] && echo /usr/local/bin/docker").Trim
					If (sDOCKER_EXE = "") Then sDOCKER_EXE = DoShellCommand("[ -f /snap/bin/docker ] && echo /snap/bin/docker").Trim
					If bCODESIGN_ENABLED Then
					sFILE_ACS_JSON = DoShellCommand("[ -f ~/.aas-codesign/acs.json ] && echo ~/.aas-codesign/acs.json").Trim
					sFILE_AZURE_JSON = DoShellCommand("[ -f ~/.aas-codesign/azure.json ] && echo ~/.aas-codesign/azure.json").Trim
					sFILE_PFX_JSON = DoShellCommand("[ -f ~/.pfx-codesign/pfx.json ] && echo ~/.pfx-codesign/pfx.json").Trim
					sFILE_PFX_CERTIFICATE = DoShellCommand("[ -f ~/.pfx-codesign/certificate.pfx ] && echo ~/.pfx-codesign/certificate.pfx").Trim
					End If
					Else
					If (Not bSILENT) Then Print "InnoSetup: Xojo IDE running on unknown Target"
					Return
					End If
					
					Var bCODESIGN_AAS As Boolean = (sFILE_ACS_JSON <> "") And (sFILE_AZURE_JSON <> "")
					Var bCODESIGN_PFX As Boolean = (sFILE_PFX_JSON <> "") And (sFILE_PFX_CERTIFICATE <> "")
					
					If (sPROJECT_PATH = "") Then
					If (Not bSILENT) Then Print "CreateZIP: Could not get the Environment Variable PROJECT_PATH from the Xojo IDE." + EndOfLine + EndOfLine + "Unfortunately, it's empty.... try again after re-launching the Xojo IDE and/or rebooting your machine."
					Return
					End If
					
					'Check InnoSetup Script
					If (sINNOSETUP_SCRIPT <> "") Then
					sINNOSETUP_SCRIPT = sINNOSETUP_SCRIPT.ReplaceAll("/", sCHAR_FOLDER_SEPARATOR).ReplaceAll("\", sCHAR_FOLDER_SEPARATOR)
					If TargetWindows Then 'Xojo IDE is running on Windows
					sINNOSETUP_SCRIPT = DoShellCommand("if exist """ + sPROJECT_PATH + sCHAR_FOLDER_SEPARATOR + sINNOSETUP_SCRIPT + """ echo " + sPROJECT_PATH + sCHAR_FOLDER_SEPARATOR + sINNOSETUP_SCRIPT).Trim
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					sINNOSETUP_SCRIPT = DoShellCommand("[ -f """ + sPROJECT_PATH + sCHAR_FOLDER_SEPARATOR + sINNOSETUP_SCRIPT + """ ] && echo " + sPROJECT_PATH + sCHAR_FOLDER_SEPARATOR + sINNOSETUP_SCRIPT).Trim
					End If
					End If
					
					If (sINNOSETUP_SCRIPT = "") Then
					If (Not bSILENT) Then Print "InnoSetup: No InnoSetup Script"
					Return
					End If
					
					Var bCODESIGN_AVAILABLE As Boolean
					If bCODESIGN_ENABLED Then
					bCODESIGN_AVAILABLE = bCODESIGN_AAS Or bCODESIGN_PFX
					If (Not bCODESIGN_AVAILABLE) And (Not bSILENT) Then
					Print "InnoSetup:" + EndOfLine + _
					"acs.json and azure.json not found in [UserHome]-[.aas-codesign]-[acs|azure.json]" + EndOfLine + _
					"pfx.json and certificate.pfx not found in [UserHome]-[.pfx-codesign]-[pfx.json|certificate.pfx]" + EndOfLine + _
					EndOfLine + _
					"Proceeding without codesigning the windows installer"
					End If
					End If
					
					'Check Docker
					Var iCHECK_DOCKER_RESULT As Integer
					Var sCHECK_DOCKER_EXE As String = DoShellCommand(sDOCKER_EXE + " --version", 0, iCHECK_DOCKER_RESULT).Trim
					If (iCHECK_DOCKER_RESULT <> 0) Or (Not sCHECK_DOCKER_EXE.Contains("Docker")) Or (Not sCHECK_DOCKER_EXE.Contains("version")) Or (Not sCHECK_DOCKER_EXE.Contains("build "))Then
					If (Not bVERYSILENT) Then Print "InnoSetup: Docker not available"
					Return
					End If
					
					Var sCHECK_DOCKER_PROCESS As String = DoShellCommand(sDOCKER_EXE + " ps", 0, iCHECK_DOCKER_RESULT).Trim
					If (iCHECK_DOCKER_RESULT <> 0) Then
					If (Not bVERYSILENT) Then Print "InnoSetup: Docker not running"
					Return
					End If
					
					Var sPATH_PARTS() As String = sBUILD_LOCATION.Split(sCHAR_FOLDER_SEPARATOR)
					Var sAPP_FOLDERNAME As String = sPATH_PARTS(sPATH_PARTS.LastIndex)
					sPATH_PARTS.RemoveAt(sPATH_PARTS.LastIndex)
					Var sAPP_PARENT_FOLDERNAME As String = sPATH_PARTS(sPATH_PARTS.LastIndex)
					sPATH_PARTS.RemoveAt(sPATH_PARTS.LastIndex)
					Var sFOLDER_BASE As String = String.FromArray(sPATH_PARTS, sCHAR_FOLDER_SEPARATOR)
					Var sISS_RELATIVE_SOURCEPATH As String = sAPP_PARENT_FOLDERNAME + "/" + sAPP_FOLDERNAME
					
					'Run InnoSetup (and CodeSign) in Docker Container
					Var sINNOSETUP_PARAMETERS() As String
					
					Var bENV_AAS_CREDENTIAL As Boolean
					Var bENV_PFX_CREDENTIAL As Boolean
					
					'Enable Codesigning
					If bCODESIGN_AVAILABLE Then
					If (sFILE_ACS_JSON <> "") And (sFILE_AZURE_JSON <> "") Then
					sINNOSETUP_PARAMETERS.Add("""/SAAS=Z:/usr/local/bin/aas-codesign.bat $f""")
					sINNOSETUP_PARAMETERS.Add("/DcsCodeSignAAS")
					ElseIf (sFILE_PFX_JSON <> "") And (sFILE_PFX_CERTIFICATE <> "") Then
					sINNOSETUP_PARAMETERS.Add("""/SAAS=Z:/usr/local/bin/pfx-codesign.bat $f""")
					sINNOSETUP_PARAMETERS.Add("/DcsCodeSignAAS")
					End If
					
					'Get Credential from Secure Storage
					If bCODESIGN_AAS Or bCODESIGN_PFX Then
					Var SFILE_CREDENTIAL As String
					Var sCREDENTIAL_COMMAND As String
					
					If TargetWindows Then 'Xojo IDE is running on Windows
					If bCODESIGN_AAS Then
					SFILE_CREDENTIAL = DoShellCommand("if exist %USERPROFILE%\.aas-codesign\aas-codesign-credential.ps1 echo %USERPROFILE%\.aas-codesign\aas-codesign-credential.ps1").Trim
					ElseIf bCODESIGN_PFX Then
					SFILE_CREDENTIAL = DoShellCommand("if exist %USERPROFILE%\.pfx-codesign\pfx-codesign-credential.ps1 echo %USERPROFILE%\.pfx-codesign\pfx-codesign-credential.ps1").Trim
					End If
					If (SFILE_CREDENTIAL <> "") Then
					sCREDENTIAL_COMMAND = "powershell """ + SFILE_CREDENTIAL + """"
					End If
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					If bCODESIGN_AAS Then
					SFILE_CREDENTIAL = DoShellCommand("[ -f ~/.aas-codesign/aas-codesign-credential.sh ] && echo ~/.aas-codesign/aas-codesign-credential.sh").Trim
					ElseIf bCODESIGN_PFX Then
					SFILE_CREDENTIAL = DoShellCommand("[ -f ~/.pfx-codesign/pfx-codesign-credential.sh ] && echo ~/.pfx-codesign/pfx-codesign-credential.sh").Trim
					End If
					If (SFILE_CREDENTIAL <> "") Then
					Call DoShellCommand("chmod 755 """ + SFILE_CREDENTIAL + """") 'just to make sure it's executable
					sCREDENTIAL_COMMAND = SFILE_CREDENTIAL
					End If
					End If
					
					If (sCREDENTIAL_COMMAND <> "") Then
					'Once the Credential Helper Script is in place, we expect to get a value from it
					Var iCREDENTIAL_RESULT As Integer
					Var sCREDENTIAL As String = DoShellCommand(sCREDENTIAL_COMMAND, 0, iCREDENTIAL_RESULT).Trim
					If (iCREDENTIAL_RESULT <> 0) Or (sCREDENTIAL = "") Then
					Print  "InnoSetup: Could not retrieve " + If(bCODESIGN_AAS, "AAS", "PFX") + " Credential"
					Return
					End If
					
					'Use Environment Variable
					If bCODESIGN_AAS Then
					EnvironmentVariable("AZURE_CLIENT_SECRET") = sCREDENTIAL
					bENV_AAS_CREDENTIAL = true
					ElseIf bCODESIGN_PFX Then
					EnvironmentVariable("PFX_PASSWORD") = sCREDENTIAL
					bENV_PFX_CREDENTIAL = true
					End If
					End If
					End If
					End If
					
					'Parameters for our universal InnoSetup Script
					sINNOSETUP_PARAMETERS.Add("/DcsProductName=""" + sISS_csProductName + """")
					sINNOSETUP_PARAMETERS.Add("/DcsProductNameWithStageCode=""" + sISS_csProductNameWithStageCode + """")
					sINNOSETUP_PARAMETERS.Add("/DcsExeName=""" + sISS_csExeName + """")
					sINNOSETUP_PARAMETERS.Add("/DcsAppPublisher=""" + sISS_csAppPublisher + """")
					sINNOSETUP_PARAMETERS.Add("/DcsAppPublisherURL=""" + sISS_csAppPublisherURL + """")
					sINNOSETUP_PARAMETERS.Add("/DcsOutputBaseFilename=""" + sISS_csOutputBaseFilename + """")
					
					'Define Build Target for our universal InnoSetup Script
					Select Case CurrentBuildTarget
					Case 3 'Windows (Intel, 32Bit)
					sINNOSETUP_PARAMETERS.Add("/DcsBuildTargetWIN32")
					Case 19 'Windows (Intel, 64Bit)
					sINNOSETUP_PARAMETERS.Add("/DcsBuildTargetWIN64")
					Case 25 'Windows(ARM, 64Bit)
					sINNOSETUP_PARAMETERS.Add("/DcsBuildTargetARM64")
					End Select
					
					'System Requirements for built Windows application
					sINNOSETUP_PARAMETERS.Add("/DcsMinVersion=""" + sMINVERSION + """")
					
					'Docker related Parameters
					sINNOSETUP_PARAMETERS.Add("/O""Z:/data""") 'Output in Folder
					sINNOSETUP_PARAMETERS.Add("/Dsourcepath=""Z:/data/" + sISS_RELATIVE_SOURCEPATH + """") 'Folder of built App
					sINNOSETUP_PARAMETERS.Add("""Z:/tmp/innosetup-script.iss""") 'we mount the script to this location
					
					Var sISCC_SH_ARGUMENT As String
					If TargetWindows Then 'Xojo IDE is running on Windows
					sISCC_SH_ARGUMENT = """" + String.FromArray(sINNOSETUP_PARAMETERS, " ").ReplaceAll("$f", "\$f").ReplaceAll("""", "\""") + """"
					ElseIf TargetMacOS Or TargetLinux Then 'Xojo IDE running on macOS or Linux
					sISCC_SH_ARGUMENT = "'" + String.FromArray(sINNOSETUP_PARAMETERS, " ").ReplaceAll("$f", "\$f") + "'"
					End If
					
					Var sINNOSETUP_COMMAND As String = _
					sDOCKER_EXE + " run " + _
					"--rm " + _
					If(sFILE_ACS_JSON <> "", "-v """ + sFILE_ACS_JSON + """:/etc/aas-codesign/acs.json ", "") + _
					If(sFILE_AZURE_JSON <> "", "-v """ + sFILE_AZURE_JSON + """:/etc/aas-codesign/azure.json ", "") + _
					If(bENV_AAS_CREDENTIAL, "-e AZURE_CLIENT_SECRET ", "") + _
					If(sFILE_PFX_JSON <> "", "-v """ + sFILE_PFX_JSON + """:/etc/pfx-codesign/pfx.json ", "") + _
					If(sFILE_PFX_CERTIFICATE <> "", "-v """ + sFILE_PFX_CERTIFICATE + """:/etc/pfx-codesign/certificate.pfx ", "") + _
					If(bENV_PFX_CREDENTIAL, "-e PFX_PASSWORD ", "") + _
					"-v """ + sFOLDER_BASE + """:/data " + _
					"-v """ + sINNOSETUP_SCRIPT + """:/tmp/innosetup-script.iss " + _
					"-w /data " + _
					"--entrypoint iscc.sh " + _
					sDOCKER_IMAGE + " " + _
					sISCC_SH_ARGUMENT
					
					Var iINNOSETUP_RESULT As Integer
					Var sINNOSETUP_OUTPUT As String = DoShellCommand(sINNOSETUP_COMMAND, 0, iINNOSETUP_RESULT)
					
					If (iINNOSETUP_RESULT <> 0) And (Not bVERYSILENT) Then
					If (iINNOSETUP_RESULT <> 125) Then
					Var iCHECK_DOCKERIMAGE_RESULT As Integer
					Var sCHECK_DOCKERIMAGE_OUTPUT As String = DoShellCommand(sDOCKER_EXE + " image inspect " + sDOCKER_IMAGE, 0, iCHECK_DOCKERIMAGE_RESULT)
					If (iCHECK_DOCKERIMAGE_RESULT <> 0) Then
					Print "InnoSetup: Docker Image '" + sDOCKER_IMAGE + "' not available" + EndOfLine + EndOfLine + _
					"This sometimes occurs if Docker hasn't been able to automatically download the Docker Image when executing a 'docker run' command." + EndOfLine + EndOfLine + _
					"Download the required Docker Image once manually by executing this command in a Terminal Window:" + EndOfLine + _
					sDOCKER_EXE + " image pull " + sDOCKER_IMAGE
					Return
					End If
					End If
					
					Clipboard = sINNOSETUP_OUTPUT
					Print "InnoSetup: iscc.sh Error" + EndOfLine + _
					"[ExitCode: " + iINNOSETUP_RESULT.ToString + "]" + EndOfLine + EndOfLine + _
					"Note: Shell Output is available in Clipboard."
					End If
					
				End
			End
#tag EndBuildAutomation
