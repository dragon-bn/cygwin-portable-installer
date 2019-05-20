@ECHO OFF
REM --------------------------------------------------------------------------
REM Batch file to start Cygwin on arbitrary drive letters

SETLOCAL
  FOR /F %%D IN ("%CD%") DO SET CYGDRIVE=%%~dD

REM -- Check if we've already modified the fstab for this drive letter
  IF "%CYGDRIVE%"=="%CYGWIN_DRIVE%" GOTO :DONE

REM -- Check if the original fstab has been backed up
  IF EXIST %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab.original GOTO MAKEFSTAB
    copy %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab.original

REM -- Set up the default fstab
:MAKEFSTAB
  echo # Custom fstab for removable media                  >  %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab
  echo # See /Cygwin/etc/fstab.original for defaults      >>  %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab
  echo %CYGDRIVE%/Applis/GIT/cygwin/cygwin-portable-installer/Cygwin     /        ntfs binary 0 0 >>  %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab
  echo %CYGDRIVE%/Applis/GIT/cygwin/cygwin-portable-installer/Cygwin/bin /usr/bin ntfs binary 0 0 >>  %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab
  echo %CYGDRIVE%/Applis/GIT/cygwin/cygwin-portable-installer/Cygwin/lib /usr/lib ntfs binary 0 0 >>  %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\etc\fstab

rem -- Start up thedefault shell
  chdir %CYGDRIVE%\Applis\GIT\cygwin\cygwin-portable-installer\Cygwin\bin
  bash --login -i

ENDLOCAL

:DONE

REM We're done with the local variables, but remember to set
REM a variable that tells us the drive Cygwin is running on

  SET CYGWIN_DRIVE=%CYGDRIVE%

EXIT /B 0