# Bump version
$v = Get-Content version.txt
$parts = $v.Split('.')
$parts[1] = [int]$parts[1] + 1
$new = $parts -join '.'
$new | Set-Content version.txt

Write-Host "Version bumped to v$new"

# Build PRG
& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenWineFace.prg -y "$env:USERPROFILE/.connectiq/developer_key.der"

# Build IQ package
& "$env:APPDATA/Garmin/ConnectIQ/Sdks/connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa/bin/monkeyc.bat" -f monkey.jungle -d enduro3 -o build/KultgubbenWineFace.iq -y "$env:USERPROFILE/.connectiq/developer_key.der" -e

Write-Host "Build klar! Filerna finns i build/"
