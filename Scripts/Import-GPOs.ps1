﻿#Import all GPOs into Active Directory Group Policy
#Script from https://www.microsoft.com/en-us/download/details.aspx?id=55319 with some edit 

$rootDir = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
Import-Module activedirectory ; Import-Module grouppolicy
import-module ($rootDir+'.\gpomigration\gpomigration.psm1') -force

$DomainDNSName=(Get-ADDomain).DNSRoot
$DomainName=(Get-ADDomain).NetBIOSName


$GpoMap = .\MapGuidsToGpoNames.ps1 ..\GPOs

$parentDir = [System.IO.Path]::GetDirectoryName($rootDir)
$gpoDir = [System.IO.Path]::Combine($parentDir, "GPOs")
$wmiDir = [System.IO.Path]::Combine($parentDir, "wmi")

Write-Host "Importing the following GPOs:" -ForegroundColor Cyan
Write-Host
$GpoMap.Keys | ForEach-Object { 
    Write-Host
    if ($_.startsWith("MSFT")){ $GPOName = "$($_)"}
    else {$GPOName = "#AB#_$($_)" }
    $guid = $GpoMap[$_]
    # Update Domain Name in all XML files recursively
    Get-ChildItem -Path $gpoDir -Recurse -Filter *.xml | ForEach-Object {
        (Get-Content -Path $_.FullName -Raw) -replace "contoso.com", $DomainDNSName | Set-Content -Path $_.FullName
        (Get-Content -Path $_.FullName -Raw) -replace "contoso", $DomainName | Set-Content -Path $_.FullName
    }
    Write-Host ($guid + ": " + $GPOName) -ForegroundColor Cyan
    Import-GPO -BackupId $guid -Path $gpoDir -TargetName "$GPOName" -CreateIfNeeded 
}

    # Import WMIFilters
    Get-ChildItem -Path $wmiDir -Filter *.csv | ForEach-Object {
    (Get-Content -Path $_.FullName -Raw) -replace "contoso.com", $DomainDNSName | Set-Content -Path $_.FullName
    (Get-Content -Path $_.FullName -Raw) -replace "contoso", $DomainName | Set-Content -Path $_.FullName
}
    $DestServer = (Get-ADDomain | Select-Object PDCEmulator).PDCEmulator
    Import-WMIFilter -DestServer $DestServer -Path $wmiDir


# Copy all folders recursively from the script's parent folder sysvol to C:\Windows\sysvol
$sourceSysvol = [System.IO.Path]::Combine($parentDir, "sysvol")
$destinationSysvol = "C:\Windows\sysvol"
Copy-Item -Path $sourceSysvol -Destination $destinationSysvol -Recurse -Force