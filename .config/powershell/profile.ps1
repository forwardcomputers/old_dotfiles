
# Install-Module posh-git -Scope CurrentUser -Force
# Install-Module oh-my-posh -Scope CurrentUser -Force
# Install-Module psreadline -Scope CurrentUser -Force
# Install-Module get-childitemcolor -Scope CurrentUser -AllowClobber -Force

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

if ( $PSVersionTable.PSVersion.Major -ge 5 ) {
  Import-Module Get-ChildItemColor
  Import-Module posh-git
  Import-Module oh-my-posh
  if ( (get-Module oh-my-posh).Version.Major -lt 3 ) {
    Set-Theme Agnoster
  } else {
    Set-PoshPrompt -Theme Agnoster
  }
}

$Shell            = $Host.UI.RawUI
$size             = $Shell.BufferSize
$size.width       = 180
$size.height      = 9000
$Shell.BufferSize = $size
$size             = $Shell.WindowSize
$size.width       = 180
$size.height      = 50
$Shell.WindowSize = $size

$env:SHARE = "$env:systemdrive\opt\filer\os"
$env:DOCKERCOMPOSE = "$env:share\docker-compose"
$env:DOCKERFILES = "$env:share\dockerfiles"
$env:PXE = "$env:share\pxe"

function upgrade {
  Write-Output "`nUpgrading Chocolatey packages"
  choco upgrade all -s "https://chocolatey.org/api/v2/;\opt\filer\os\win\apps\chocolatey-packages\automatic" -y
  Write-Output "`n`nUpgrading Windows"
  Install-WindowsUpdate -AcceptAll -IgnoreReboot
}


Remove-Item Alias:cd
function cd {
  if ( $args[0] -eq '-' ) { 
    $pwd = $OLDPWD;
  } else {
    $pwd = $args[0];
  }
  $tmp = pwd;
  if( $pwd ) { 
    set-location $pwd;
  }
  set-variable -name OLDPWD -value $tmp -scope global; 
}

function = { Set-Location -Path - }
function .. { Set-Location -Path .. }
function ... { Set-Location -Path ..\.. }
function .... { Set-Location -Path ..\..\.. }
function ..... { Set-Location -Path ..\..\..\.. }
Function ~ { Set-Location -Path $HOME }
Function share { Set-Location -Path $env:SHARE }

