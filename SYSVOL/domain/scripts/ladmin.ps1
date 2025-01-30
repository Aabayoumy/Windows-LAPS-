# Create ladmin and check for LAPS event ID
if ((Get-LocalUser | Where-Object Name -eq "ladmin").Count -eq 0) {
    Add-Type -AssemblyName System.Web
    $generatedPassword = [System.Web.Security.Membership]::GeneratePassword(12, 2) | ConvertTo-SecureString -AsPlainText -Force
    New-LocalUser -Name "ladmin" -Password $generatedPassword -FullName "adminuser" -Description "Local Admin For LAPS"
    Add-LocalGroupMember -Name 'Administrators' -Member 'ladmin'
    Reset-LapsPassword
    Start-Sleep 30
}
$registryKeyPath = "HKLM:\Software\gbg-laps"
if (-not (Test-Path -Path $registryKeyPath) -and (Get-WinEvent -LogName 'Microsoft-Windows-LAPS/Operational' | Where-Object {$_.id -eq 10020}).Count -ge 1) {
    New-Item -Path $registryKeyPath -Force | Out-Null
    New-ItemProperty -Path $registryKeyPath -Name "success" -Value "true" -Force | Out-Null
}
