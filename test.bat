@echo off
setlocal

path %PATH%;%ProgramFiles(x86)%\EMET;%ProgramFiles%\EMET
path %PATH%;%ProgramFiles(x86)%\EMET 4.0;%ProgramFiles%\EMET 4.0
path %PATH%;%ProgramFiles(x86)%\EMET 4.1;%ProgramFiles%\EMET 4.1
path %PATH%;%ProgramFiles(x86)%\EMET 5.0;%ProgramFiles%\EMET 5.0
path %PATH%;%ProgramFiles(x86)%\EMET 5.1;%ProgramFiles%\EMET 5.1
path %PATH%;%ProgramFiles(x86)%\EMET 5.2;%ProgramFiles%\EMET 5.2
path %PATH%;%ProgramFiles(x86)%\EMET 5.5;%ProgramFiles%\EMET 5.5

pushd %~dp0
bcdedit /enum {current} | find "nx"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation 2> nul | find /i "DisableExceptionChainValidation"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages 2> nul | find /i "MoveImages"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MitigationOptions 2> nul | find /i "MitigationOptions"

for %%f in (dep_*.exe sehop_*.exe aslr_runtime_*.exe) do (
	reg add "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting\ExcludedApplications" /v %%f /t REG_DWORD /d 1 /f > nul 2> nul
	echo ^	%%f
	exec %%f
	EMET_Conf.exe --set %%f +DEP +SEHOP +MandatoryASLR > nul 2> nul && (
		echo ^	%%f EMET applied
		exec %%f
		EMET_Conf.exe --delete %%f > nul 2> nul
		reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%f" /f > nul 2> nul
	)
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting\ExcludedApplications" /v %%f /f > nul 2> nul
	echo.
)

for %%f in (aslr_loadtime_*.exe) do (
	reg add "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting\ExcludedApplications" /v %%f /t REG_DWORD /d 1 /f > nul 2> nul
	for %%d in (DLL_aslraware.dll DLL_relocatable.dll DLL_fixed.dll) do (
		copy /y %%d DLL_aslr.dll > nul
		echo ^	%%f^(%%d^)
		exec %%f
		EMET_Conf.exe --set %%f +DEP +SEHOP +MandatoryASLR > nul 2> nul && (
			echo ^	%%f^(%%d^) EMET applied
			exec %%f
			EMET_Conf.exe --delete %%f > nul 2> nul
			reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\%%f" /f > nul 2> nul
		)
	)
	reg delete "HKCU\SOFTWARE\Microsoft\Windows\Windows Error Reporting\ExcludedApplications" /v %%f /f > nul 2> nul
	echo.
)

del /q "%LOCALAPPDATA%\CrashDumps\*.dmp" 2> nul
popd
endlocal