#!/usr/bin/env pwsh

Param(
  # Remote SMB //hostname/path
  $smbserver=$null,
  # URL to find custom jalview_properties file
  $propsurl=$null
)

$REMOTESMBSERVER = $smbserver
$JALVIEWPROPERTIESURL = $propsurl

# Feel free to change the paths in the fully capitalised variables below though these have sensible defaults

$JALVIEW_DOWNLOAD_URL = "http://www.jalview.org/getdown/release/install4j/1.8/Jalview-2_11_1_4-windows-x64-java_8.exe"

$pwd = ( Get-Location )
$LOCALMOUNTPOINT = Join-Path -Path $pwd -ChildPath "jalview_alignments"

# Jalview would normally be installed in %LOCALAPPDIR%\Jalview
$JALVIEWDIR = Join-Path -Path $Env:LOCALAPPDATA -ChildPath "Jalview"

# Surprisingly complicated to generically get the actual Downloads folder
$DOWNLOADSDIR = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

# TODO: Check and mount the mount-point
#
If ( ! ( Test-Path -Path $LOCALMOUNTPOINT -PathType Container ) ) {
  New-Item -Path ( Split-Path -Path $LOCALMOUNTPOINT -Parent ) -Name ( Split-Path -Path $LOCALMOUNTPOINT -Leaf ) -ItemType "directory"
  If ( ! ( $REMOTESMBSERVER -eq $null ) ) {
    Write-Host "Mounting SMB share"
    New-SmbMapping -LocalPath $LOCALMOUNTPOINT -RemotePath $REMOTESMBSERVER
  }
}

$jalviewExe = Join-Path -Path $JALVIEWDIR -ChildPath "jalview.exe"
If ( Test-Path -Path $jalviewExe -PathType Leaf ) {
  Write-Host "Jalview is already installed"
} Else {
# install Jalview silently
  Write-Host "Downloading Jalview installer"
  $jalviewInstallerExe = Join-Path -Path $DOWNLOADSDIR -ChildPath "jalview_windows_installer.exe"
  Invoke-WebRequest -Uri $JALVIEW_DOWNLOAD_URL -OutFile $jalviewInstallerExe
  If ( Test-Path -Path $jalviewInstallerExe -PathType Leaf ) {
    Write-Host "Running Jalview installer"
    Start-Process -NoNewWindow -Wait -FilePath $jalviewInstallerExe -ArgumentList "-q", "-dir", $JALVIEWDIR, "-splash", "Jalview installing...", -alerts
    Remove-Item -Path $jalviewInstallerExe
  } Else {
    Throw "Failed to download Jalview Installer from '${JALVIEW_DOWNLOAD_URL}'"
  }
}

$jreHome = Join-Path -Path $JALVIEWDIR -ChildPath "jre"
$keytoolExe = Join-Path -Path $jreHome -ChildPath "bin/keytool.exe"
$keyStore = Join-Path -Path $jreHome -ChildPath "lib/security/cacerts"

# function addCert takes -Alias and -URL which downloads the $URL (as Downloads/tempcert) and adds it to the
# Jalview bundled JRE keystore and then deletes the tempcert file.
# We're re-using the userAgent from earlier.
$tempCert = Join-Path -Path $DOWNLOADSDIR -ChildPath "tempcert"

Function Add-Cert {
  Param($URL, $Alias)
  If ( Test-Path -Path $tempCert ) {
    Remove-Item -Path $tempCert
  }
  $tempOutputFile = New-TemporaryFile
  Invoke-WebRequest -Uri $URL -OutFile $tempCert
  Start-Process -NoNewWindow -Wait -RedirectStandardOutput $tempOutputFile -FilePath $keytoolExe -ArgumentList "-import", "-trustcacerts", "-keystore", $keyStore, "-storepass", "changeit", "-noprompt", "-alias",  $Alias, "-file", $tempCert
  $output = @( Get-Content -Path $tempOutputFile )
  Write-Host $output[0]
  Remove-Item -Path $tempOutputFile
  Remove-Item -Path $tempCert
}

Write-Host "Installing local certificates"
Add-Cert -Alias "rocherootca1" -URL "https://certinfo.roche.com/rootcerts/Roche%20Root%20CA%201.crt"
Add-Cert -Alias "rocheenterpriseca1" -URL "https://certinfo.roche.com/rootcerts/RocheEnterpriseCA1.crt"
Add-Cert -Alias "rocheenterpriseca2" -URL "https://certinfo.roche.com/rootcerts/RocheEnterpriseCA2.crt"
Add-Cert -Alias "rocherootca1g2" -URL "https://certinfo.roche.com/rootcerts/Roche%20Root%20CA%201%20-%20G2.crt"
Add-Cert -Alias "rocheenterpriseca1g2" -URL "https://certinfo.roche.com/rootcerts/Roche%20Enterprise%20CA%201%20-%20G2.crt"
Add-Cert -Alias "rocheg3rootca" -URL "https://certinfo.roche.com/rootcerts/Roche%20G3%20Root%20CA.crt"
Add-Cert -Alias "rocheg3issuingca1" -URL "https://certinfo.roche.com/rootcerts/Roche%20G3%20Issuing%20CA%201.crt"
Add-Cert -Alias "rocheg3issuingca2" -URL "https://certinfo.roche.com/rootcerts/Roche%20G3%20Issuing%20CA%202.crt"
Add-Cert -Alias "rocheg3issuingca3" -URL "https://certinfo.roche.com/rootcerts/Roche%20G3%20Issuing%20CA%203.crt"
Add-Cert -Alias "rocheg3issuingca4" -URL "https://certinfo.roche.com/rootcerts/Roche%20G3%20Issuing%20CA%204.crt"

# get the bespoke jalview_properties file and put into place
if ( ! ( $JALVIEWPROPERTIESURL -eq $null ) ) {
  Write-Host "Installing .jalview_properties settings file"
  $jalviewPropertiesDownloaded = Join-Path -Path $DOWNLOADSDIR -ChildPath "jalview_properties"
  $jalviewPropertiesFile = Join-Path -Path $Env:USERPROFILE -ChildPath ".jalview_properties" 
  $jalviewPropertiesBackupFile = Join-Path -Path $Env:USERPROFILE -ChildPath ".jalview_properties_bak" 
  Invoke-WebRequest -Uri $JALVIEWPROPERTIESURL -OutFile $jalviewPropertiesDownloaded
  If ( Test-Path $jalviewPropertiesFile ) {
    Remove-Item -Path $jalviewPropertiesBackupFile
    Move-Item -Path $jalviewPropertiesFile -Destination $jalviewPropertiesBackupFile
  }
  Move-Item -Path $jalviewPropertiesDownloaded -Destination $jalviewPropertiesFile
}

Write-Host "Jalview is now installed with bespoke certificates and settings"
Write-Host "Ending in 5 seconds"
Start-Sleep -s 5
