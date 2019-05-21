<#
Copyright 2017-2019 by Vegard IT GmbH (https://vegardit.com) and the cygwin-portable-installer contributors.
SPDX-License-Identifier: Apache-2.0

@author Sebastian Thomschke, Vegard IT GmbH
@author_PowerShell Stéphane DELSUQUET

ABOUT
=====
This self-contained Windows batch file creates a portable Cygwin (https://cygwin.com/mirrors.html) installation.
By default it automatically installs :
 - apt-cyg (cygwin command-line package manager, see https://github.com/kou1okada/apt-cyg)
 - bash-funk (Bash toolbox and adaptive Bash prompt, see https://github.com/vegardit/bash-funk)
 - ConEmu (multi-tabbed terminal, https://conemu.github.io/)
 - Ansible (deployment automation tool, see https://github.com/ansible/ansible)
 - AWS CLI (AWS cloud command line tool, see https://github.com/aws/aws-cli)
 - testssl.sh (command line tool to check SSL/TLS configurations of servers, see https://testssl.sh/)
#>
Clear-Host;
#region ConfigCustomizationStart
<#
============================================================================================================
CONFIG CUSTOMIZATION START
============================================================================================================
#>
write-host -object "Config Customization Start";

# You can customize the following variables to your needs before running the batch file:

# set proxy if required (unfortunately Cygwin setup.exe does not have commandline options to specify proxy user credentials)
#$PROXY_HOST=
#$PROXY_PORT=8080

# change the URL to the closest mirror https://cygwin.com/mirrors.html
#$CYGWIN_MIRROR="http://linux.rz.ruhr-uni-bochum.de/download/cygwin";
$CYGWIN_MIRROR="http://cygwin.mirror.globo.tech/";

# one of: auto,64,32 - specifies if 32 or 64 bit version should be installed or automatically detected based on current OS architecture
$CYGWIN_ARCH="auto";

# choose a user name under Cygwin
$CYGWIN_USERNAME="root";

# select the packages to be installed automatically via apt-cyg
#set CYGWIN_PACKAGES=bash-completion,bc,curl,expect,git,git-svn,gnupg,inetutils,lz4,mc,nc,openssh,openssl,perl,python,pv,ssh-pageant,screen,subversion,unzip,vim,wget,zip,zstd
$CYGWIN_PACKAGES="bash-completion,bc,curl,dos2unix,expect,git,git-svn,gnupg,inetutils,lz4,mc,nc,openssh,openssl,perl,python,pv,ssh-pageant,screen,subversion,unzip,vim,wget,zip,zstd";

# if $to 'yes' the local package cache created by cygwin setup will be deleted after installation/update
$DELETE_CYGWIN_PACKAGE_CACHE="no";

# if $to 'yes' the apt-cyg command line package manager (https://github.com/kou1okada/apt-cyg) will be installed automatically
$INSTALL_APT_CYG="yes";

# if $to 'yes' the bash-funk adaptive Bash prompt (https://github.com/vegardit/bash-funk) will be installed automatically
$INSTALL_BASH_FUNK="no";

# if $to 'yes' Ansible (https://github.com/ansible/ansible) will be installed automatically
$INSTALL_ANSIBLE="no";
$ANSIBLE_GIT_BRANCH="stable-2.7";

# if $to 'yes' AWS CLI (https://github.com/aws/aws-cli) will be installed automatically
$INSTALL_AWS_CLI="no";

# if $to 'yes' testssl.sh (https://testssl.sh/) will be installed automatically
$INSTALL_TESTSSL_SH="no";
# name of the GIT branch to install from, see https://github.com/drwetter/testssl.sh/
$TESTSSL_GIT_BRANCH="2.9.5";

# use ConEmu based tabbed terminal instead of Mintty based single window terminal, see https://conemu.github.io/
$INSTALL_CONEMU="no";
$CON_EMU_OPTIONS='-Title cygwin-portable -QuitOnClose';

# add more path if required, but at the cost of runtime performance (e.g. slower forks)
$CYGWIN_PATH='%%SystemRoot%%\system32;%%SystemRoot%%';

# $Mintty options, see https://cdn.rawgit.com/mintty/mintty/master/docs/mintty.1.html#CONFIGURATION
$MINTTY_OPTIONS='--Title cygwin-portable -o Columns=160 -o Rows=50 -o BellType=0 -o ClicksPlaceCursor=yes -o CursorBlinks=yes -o CursorColour=96,96,255 -o CursorType=Block -o CopyOnSelect=yes -o RightClickAction=Paste -o Font="Courier New" -o FontHeight=10 -o FontSmoothing=None -o ScrollbackLines=10000 -o Transparency=off -o Term=xterm-256color -o Charset=UTF-8 -o Locale=C';

<#
# ============================================================================================================
# CONFIG CUSTOMIZATION END
# ============================================================================================================
#>
#endregion


#region InstallingCygwin
Write-Host -Object " `
########################################################### `
# Installing [Cygwin Portable]... `
########################################################### `
.";

#$INSTALL_ROOT="C:\Perso\MesApplis";
$INSTALL_ROOT=Split-Path -Path $MyInvocation.MyCommand.Definition -Parent;
Write-Host -Object $INSTALL_ROOT;

$CYGWIN_ROOT=Join-Path $INSTALL_ROOT -ChildPath "Cygwin";
Write-Host -Object "Dossier racine : $CYGWIN_ROOT";

Write-Host -Object "Creating Cygwin root [$CYGWIN_ROOT]...";
if(!(Test-Path -Path $CYGWIN_ROOT -PathType Container))
   {
      New-Item -Type Directory -Path $CYGWIN_ROOT -Force;
   }

# https://blogs.msdn.microsoft.com/david.wang/2006/03/27/howto-detect-process-bitness/
if ([System.Environment]::Is64BitProcess -eq $true)
   {
      Write-Host -Object "Architecture 64 bits";
      $CYGWIN_SETUP="setup-x86_64.exe";
   }
   else
   {
      Write-Host -Object "Architecture 32 bits";
      $CYGWIN_SETUP="setup-x86.exe";
   }
Write-Host -Object "Programme d'installation CYGMIN : $CYGWIN_SETUP";

$DownloadFileSetup=Join-Path $INSTALL_ROOT -ChildPath $CYGWIN_SETUP;
Write-Host -Object "Chemin de l'installateur CYGWIN : $DownloadFileSetup";
if (Test-Path -Path $DownloadFileSetup -PathType Leaf)
   {
      Write-Host -Object "Suppression de l'installateur CYGWIN : $DownloadFileSetup";
      Remove-Item -Path $DownloadFileSetup;
   }

# https://blog.jourdant.me/post/3-ways-to-download-files-with-powershell
# https://stackoverflow.com/questions/14263359/access-web-using-powershell-and-proxy
$url = "http://cygwin.org/$CYGWIN_SETUP";
Write-Host -Object "URL de téléchargement de l'installateur CYGWIN : $url";

$start_time = Get-Date;

Write-Host -Object "Téléchargement de l'installateur CYGWIN depuis : $url.";
$wc = New-Object System.Net.WebClient;
$wc.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials;
$wc.DownloadFile($url, $DownloadFileSetup);

Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)";

# Ajout de composant si l'installation de - apt-cyg - est demandée.
if ($INSTALL_APT_CYG -ieq "yes")
   {
   $CYGWIN_PACKAGES="wget,ca-certificates,gnupg,$CYGWIN_PACKAGES";
   }

# Ajout de composant si l'installation de - ANSIBLE - est demandée.
if ($INSTALL_ANSIBLE -ieq "yes")
   {
      $CYGWIN_PACKAGES="git,openssh,python-jinja2,python-six,python-yaml,$CYGWIN_PACKAGES";
   }
  
# if conemu install is selected we need to be able to extract 7z archives, otherwise we need to install mintty
if ($INSTALL_CONEMU -ieq "yes")
   {
      $CYGWIN_PACKAGES="bsdtar,$CYGWIN_PACKAGES"
   } else {
      $CYGWIN_PACKAGES="mintty,$CYGWIN_PACKAGES";
   }
  
  if ($INSTALL_TESTSSL_SH -ieq "yes")
   {
      $CYGWIN_PACKAGES="bind-utils,$CYGWIN_PACKAGES";
   }


<#
Cygwin setup 2.897

Command Line Options:

    --allow-unsupported-windows    Allow old, unsupported Windows versions
 -a --arch                         Architecture to install (x86_64 or x86)
 -C --categories                   Specify entire categories to install
 -o --delete-orphans               Remove orphaned packages
 -A --disable-buggy-antivirus      Disable known or suspected buggy anti virus
                                   software packages during execution.
 -D --download                     Download packages from internet only
 -f --force-current                Select the current version for all packages
 -h --help                         Print help
 -I --include-source               Automatically install source for every
                                   package installed
 -i --ini-basename                 Use a different basename, e.g. "foo",
                                   instead of "setup"
 -U --keep-untrusted-keys          Use untrusted keys and retain all
 -L --local-install                Install packages from local directory only
 -l --local-package-dir            Local package directory
 -m --mirror-mode                  Skip package availability check when
                                   installing from local directory (requires
                                   local directory to be clean mirror!)
 -B --no-admin                     Do not check for and enforce running as
                                   Administrator
 -d --no-desktop                   Disable creation of desktop shortcut
 -r --no-replaceonreboot           Disable replacing in-use files on next
                                   reboot.
 -n --no-shortcuts                 Disable creation of desktop and start menu
                                   shortcuts
 -N --no-startmenu                 Disable creation of start menu shortcut
 -X --no-verify                    Don't verify setup.ini signatures
    --no-version-check             Suppress checking if a newer version of
                                   setup is available
 -O --only-site                    Do not download mirror list.  Only use sites
                                   specified with -s.
 -M --package-manager              Semi-attended chooser-only mode
 -P --packages                     Specify packages to install
 -p --proxy                        HTTP/FTP proxy (host:port)
 -Y --prune-install                Prune the installation to only the requested
                                   packages
 -K --pubkey                       URL of extra public key file (gpg format)
 -q --quiet-mode                   Unattended setup mode
 -c --remove-categories            Specify categories to uninstall
 -x --remove-packages              Specify packages to uninstall
 -R --root                         Root installation directory
 -S --sexpr-pubkey                 Extra public key in s-expr format
 -s --site                         Download site URL
 -u --untrusted-keys               Use untrusted saved extra keys
 -g --upgrade-also                 Also upgrade installed packages
    --user-agent                   User agent string for HTTP requests
 -v --verbose                      Verbose output
 -V --version                      Show version
 -W --wait                         When elevating, wait for elevated child
                                   process

The default is to both download and install packages, unless either --download or --local-install is specified.
#>

$CYGWIN_CACHE=$(Join-Path $CYGWIN_ROOT -ChildPath ".pkg-cache");
if (!(Test-Path -Path $CYGWIN_CACHE -PathType Container))
   {
      New-Item -Type Directory -Path $CYGWIN_CACHE -Force;
   }

Write-Host -Object "Installation de CYGWIN en cours...";

Start-Process -RedirectStandardOutput output_installation.txt -RedirectStandardError err_installation.txt.txt -Wait -FilePath "$DownloadFileSetup" -ArgumentList "--site $CYGWIN_MIRROR --root $CYGWIN_ROOT --local-package-dir $CYGWIN_CACHE --quiet-mode --packages $CYGWIN_PACKAGES --verbose";
$LastExitCode;
#Write-Host -Object "Sortie de l'installation";
#Get-Content -Path output_installation.txt;
#Write-Host -Object "Erreur de l'installation";
#Get-Content -Path err_installation.txt


if ($DELETE_CYGWIN_PACKAGE_CACHE -ieq "yes")
{
 Remove-Item -Path $CYGWIN_CACHE -Recurse -Force;
}
#endregion

#region Updater
$Updater_cmd=Join-Path -Path $INSTALL_ROOT -ChildPath "cygwin-portable-updater.cmd";
Write-Host -Object "Création du script de mise à jour [$Updater_cmd]";
$Updater_cmd_template = @"
@echo off
set CYGWIN_ROOT=$INSTALL_ROOT\$CYGWIN_SETUP
set DELETE_CYGWIN_PACKAGE_CACHE=$DELETE_CYGWIN_PACKAGE_CACHE
echo.
echo.
echo ###########################################################
echo # Updating [Cygwin Portable]...
echo ###########################################################
echo.

"$INSTALL_ROOT\$CYGWIN_SETUP" --no-admin ^
--site $CYGWIN_MIRROR ^
--root "$CYGWIN_ROOT" ^
--local-package-dir "$CYGWIN_CACHE" ^
--no-shortcuts ^
--no-desktop ^
--delete-orphans ^
--upgrade-also ^
--no-replaceonreboot ^
--quiet-mode ^|^| goto :fail

if "%DELETE_CYGWIN_PACKAGE_CACHE%" == "yes" (
   rd /s /q "$CYGWIN_ROOT\.pkg-cache"
)
echo.
echo ###########################################################
echo # Updating [Cygwin Portable] succeeded.
echo ###########################################################
timeout /T 60
goto :eof
echo.
:fail
echo ###########################################################
echo # Updating [Cygwin Portable] FAILED!
echo ###########################################################
timeout /T 60
exit /1
"@;

$Updater_cmd_template | Out-File -FilePath $Updater_cmd -Encoding utf8;
#endregion

#region DefaultLauncher

$Cygwin_bat="$CYGWIN_ROOT\Cygwin.bat";

Write-Host -Object "D?sactivation du lanceur par défaut: $Cygwin_bat.";

if (Test-Path -Path "$Cygwin_bat" -PathType Leaf)
{
   if (Test-Path -Path "$Cygwin_bat.disabled" -PathType Leaf)
   {
      Remove-Item -Path "$Cygwin_bat.disabled" -Force;
   }
   Write-Host -Object "Renommage du fichier $($Cygwin_bat)...";
   Rename-Item -Path $Cygwin_bat -NewName "$Cygwin_bat.disabled" -Force;
} 
#endregion


#region Init_sh
$Init_sh= Join-Path -Path "$CYGWIN_ROOT" -ChildPath "portable-init.sh";
Write-Host -Object "Creating [$Init_sh]...";

$Init_sh_template = @"
#!/usr/bin/env bash
#
# Map Current Windows User to root user
#
# Check if current Windows user is in /etc/passwd
USER_SID="`$(mkpasswd -c | cut -d':' -f 5)"
if ! grep -F "`$USER_SID" /etc/passwd > /dev/null; then
   echo "Mapping Windows user '`$USER_SID' to cygwin '`$USERNAME' in /etc/passwd..."
   GID="`$(mkpasswd -c | cut -d':' -f 4)"
   echo `$USERNAME:unused:1001:`$GID`:`$USER_SID:`$HOME:/bin/bash > /etc/passwd
fi

# already set in cygwin-portable.cmd:
export CYGWIN_ROOT=`$(cygpath -w /)

# adjust Cygwin packages cache path
#
export pkg_cache_dir="`$(cygpath -w "`$CYGWIN_ROOT/.pkg-cache")
# sed --in-place=".origin" '/This line is removed by the admin./c\\/cygdrive\/d\/Applis\/GIT\/cygwin\/cygwin-portable-installer\/Cygwin\/.pkg-cache\/' /etc/setup/setup.rc
sed -i -E "s/.*\\\.pkg-cache/"`$'\t'"`${pkg_cache_dir}//\\/\\\\}/" /etc/setup/setup.rc
"@;
#$Init_sh_template | Out-File -FilePath $Init_sh -Encoding utf8;
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
[System.IO.File]::WriteAllLines($Init_sh, $Init_sh_template, $Utf8NoBomEncoding)

 
Write-Host -Object "launching Bash once to initialize user home dir [$Init_sh]...";
#"%CYGWIN_ROOT%\bin\dos2unix" "$Init_sh" || goto :fail
Set-Location -Path $CYGWIN_ROOT;
Write-Host -Object "cygwin - init"
$FileName_Init_sh=[System.IO.Path]::GetFileName("$Init_sh");
Write-Host -Object "Fichiet INit $FileName_Init_sh dans le dossier $(get-location)";
Start-Process -FilePath "$CYGWIN_ROOT\bin\dos2unix" -ArgumentList "$FileName_Init_sh" -Wait -PassThru -RedirectStandardOutput output_init.txt -RedirectStandardError err_init.txt;
$LastExitCode;
Get-Content -Path output_init.txt;
Get-Content -Path err_init.txt;

Set-Location -Path $INSTALL_ROOT;
#endregion

#region Creatinglauncher
$Start_cmd=Join-Path -Path $INSTALL_ROOT -ChildPath cygwin-portable.cmd;
Write-Host -Object "Creating launcher [$Start_cmd]...";

$Start_cmd_template = @"
`@echo off
set CWD=%CD%
echo dossier courant %CWD%


SET "CDIR=%~dp0"
:: for loop requires removing trailing backslash from %~dp0 output
SET "CDIR=%CDIR:~0,-1%"
FOR %%i IN ("%CDIR%") DO SET "PARENTFOLDERNAME=%%~nxi"
ECHO Parent folder: %PARENTFOLDERNAME%
ECHO Full path: %~dp0
ECHO Disk: %~d0
:: pause>nul

set CYGWIN_DRIVE=%~d0
echo disque cygwin %CYGWIN_DRIVE%
set CYGWIN_ROOT=%~dp0cygwin
echo dossier cygwin %CYGWIN_ROOT%

for %%i in (adb.exe) do (
   set "ADB_PATH=~dp`$PATH:i"
)

set PATH=%CYGWIN_PATH%;%CYGWIN_ROOT%\bin;%ADB_PATH%
set ALLUSERSPROFILE=%CYGWIN_ROOT%\.ProgramData
set ProgramData=%ALLUSERSPROFILE%
set CYGWIN=nodosfilewarning

set USERNAME=%CYGWIN_USERNAME%
set HOME=/home/%USERNAME%
set SHELL=/bin/bash
set HOMEDRIVE=%CYGWIN_DRIVE%
set HOMEPATH=%CYGWIN_ROOT%\home\%USERNAME%
set GROUP=None
set GRP=

echo Replacing [/etc/fstab]...
(
    echo # /etc/fstab
    echo # IMPORTANT: this files is recreated on each start by cygwin-portable.cmd
    echo #
    echo #    This file is read once by the first process in a Cygwin process tree.
    echo #    To pick up changes, restart all Cygwin processes.  For a description
    echo #    see https://cygwin.com/cygwin-ug-net/using.html#mount-table
  
    echo # noacl = disable Cygwin's - apparently broken - special ACL treatment which prevents apt-cyg and other programs from working
    echo none /cygdrive cygdrive binary,noacl,posix=0,user 0 0
) > "%CYGWIN_ROOT%\etc\fstab"

%CYGWIN_DRIVE%
chdir "%CYGWIN_ROOT%\bin"
bash "%CYGWIN_ROOT%\portable-init.sh"

 if "%1" == "" (
     if "%INSTALL_CONEMU%" == "yes" (
         if "%CYGWIN_ARCH%" == "64" (
           start "" "%~dp0conemu\ConEmu64.exe" %CON_EMU_OPTIONS%
         ) else (
           start "" "%~dp0conemu\ConEmu.exe" %CON_EMU_OPTIONS%
         )
     ) else (
       mintty --nopin %MINTTY_OPTIONS% --icon %CYGWIN_ROOT%\Cygwin-Terminal.ico -
     )
 ) else (
   if "%1" == "no-mintty" (
      bash --login -i
      ) else (
      bash --login -c %*
      )
   )
   
cd "%CWD%"
"@;
#$Start_cmd_template | Out-File -FilePath $Start_cmd -Encoding utf8;
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False)
[System.IO.File]::WriteAllLines($Start_cmd, $Start_cmd_template, $Utf8NoBomEncoding)

# launching Bash once to initialize user home dir
Write-Host -Object "launching Bash once to initialize user home dir [$Start_cmd]...";
Start-Process -FilePath "$Start_cmd" -ArgumentList "whoami" -Wait -PassThru -RedirectStandardOutput output_first_launch.txt -RedirectStandardError err_first_launch.txt;
$LastExitCode;
Get-Content -Path output_first_launch.txt;
Get-Content -Path err_first_launch.txt; 

#endregion
