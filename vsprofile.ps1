param (
    [switch]$Help
)

$ErrorActionPreference = "Stop"

function Write-Color {
    param ($Text, $Color)
    Write-Host $Text -ForegroundColor $Color
}

Write-Color "Welcome to VS Code Profiles Distributor!" "Cyan"

$ProfilesDir = Join-Path $PSScriptRoot "profiles"
if (-not (Test-Path $ProfilesDir)) {
    Write-Color "Error: Profiles directory not found at $ProfilesDir" "Red"
    exit 1
}

$UserDataPath = "$env:APPDATA\Code\User"
$SettingsPath = Join-Path $UserDataPath "settings.json"
$KeybindingsPath = Join-Path $UserDataPath "keybindings.json"

if (-not (Test-Path $UserDataPath)) {
    New-Item -ItemType Directory -Force -Path $UserDataPath | Out-Null
}
if (-not (Test-Path $SettingsPath)) { "{}" | Out-File -FilePath $SettingsPath -Encoding UTF8 }
if (-not (Test-Path $KeybindingsPath)) { "[]" | Out-File -FilePath $KeybindingsPath -Encoding UTF8 }

function Merge-Json {
    param ($target, $source)
    if ($null -eq $target) { return $source }
    if ($null -eq $source) { return $target }

    if ($target -is [array] -and $source -is [array]) {
        $merged = @($target) + @($source) | Select-Object -Unique
        return $merged
    }
    
    if ($target -is [System.Management.Automation.PSCustomObject] -and $source -is [System.Management.Automation.PSCustomObject]) {
        $source.psobject.properties | ForEach-Object {
            $name = $_.Name
            $val = $_.Value
            if ($target.psobject.properties.match($name).Count) {
                $target.$name = Merge-Json -target $target.$name -source $val
            } else {
                $target | Add-Member -MemberType NoteProperty -Name $name -Value $val
            }
        }
        return $target
    }
    return $source
}

function Get-ProfileExtensions {
    param ($profile)
    $exts = @()
    if ($null -ne $profile.extensions) {
        if ($profile.extensions -is [array]) {
            $exts = $profile.extensions
        } elseif ($profile.extensions.extensions -is [array]) {
            $profile.extensions.extensions | ForEach-Object {
                if ($_ -is [System.Management.Automation.PSCustomObject] -and $null -ne $_.id) {
                    $exts += $_.id
                } elseif ($_ -is [string]) {
                    $exts += $_
                }
            }
        }
    }
    return $exts
}

function Uninstall-AllExtensions {
    Write-Color "Uninstalling all current extensions..." "Yellow"
    $extList = code --list-extensions
    foreach ($ext in $extList) {
        if ([string]::IsNullOrWhiteSpace($ext) -eq $false) {
            Write-Host "Uninstalling: $ext"
            $null = code --uninstall-extension $ext --force
        }
    }
}

function Apply-Profile {
    param ($profileName, $mode)
    
    $profileFile = Join-Path $ProfilesDir "$profileName.code-profile"
    if (-not (Test-Path $profileFile)) {
        $profileFile = Join-Path $ProfilesDir $profileName
    }

    Write-Color "`nApplying Profile: $profileName in $mode mode..." "Cyan"
    
    $profileData = Get-Content -Raw -Path $profileFile | ConvertFrom-Json

    if ($mode -eq "replace") {
        Uninstall-AllExtensions

        $settingsToSave = if ($null -ne $profileData.settings) { $profileData.settings } else { @{} }
        $settingsToSave | ConvertTo-Json -Depth 20 | Out-File -FilePath $SettingsPath -Encoding UTF8

        $kbToSave = if ($null -ne $profileData.keybindings -and $profileData.keybindings -is [array]) { $profileData.keybindings } else { @() }
        $kbToSave | ConvertTo-Json -Depth 20 | Out-File -FilePath $KeybindingsPath -Encoding UTF8

        Write-Color "Settings and Keybindings replaced." "Green"
    } elseif ($mode -eq "sync") {
        $currentSettings = Get-Content -Raw -Path $SettingsPath | ConvertFrom-Json
        $currentKb = Get-Content -Raw -Path $KeybindingsPath | ConvertFrom-Json
        
        $newSettings = Merge-Json -target $currentSettings -source $profileData.settings
        $newKb = Merge-Json -target $currentKb -source $profileData.keybindings

        $newSettings | ConvertTo-Json -Depth 20 | Out-File -FilePath $SettingsPath -Encoding UTF8
        $newKb | ConvertTo-Json -Depth 20 | Out-File -FilePath $KeybindingsPath -Encoding UTF8

        Write-Color "Settings and Keybindings merged safely." "Green"
    }

    Write-Color "Installing extensions..." "Yellow"
    $exts = Get-ProfileExtensions -profile $profileData
    foreach ($ext in $exts) {
        if ([string]::IsNullOrWhiteSpace($ext) -eq $false) {
            Write-Host "Installing: $ext"
            $null = code --install-extension $ext --force
        }
    }

    Write-Color "Profile '$profileName' successfully applied!`n" "Green"
}

function Sync-AllProfiles {
    $defaultFile = Join-Path $ProfilesDir "Default.code-profile"
    if (-not (Test-Path $defaultFile)) {
        Write-Color "Error: Default.code-profile not found!" "Red"
        exit 1
    }

    Write-Color "`nSynchronizing all profiles with Default profile..." "Cyan"
    $defaultData = Get-Content -Raw -Path $defaultFile | ConvertFrom-Json

    $profileFiles = Get-ChildItem -Path $ProfilesDir -Filter "*.code-profile"
    foreach ($file in $profileFiles) {
        if ($file.Name -ne "Default.code-profile") {
            try {
                $profileData = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json
                if ($null -eq $profileData) { continue }

                $newSettings = Merge-Json -target $defaultData.settings -source $profileData.settings
                $newKb = Merge-Json -target $defaultData.keybindings -source $profileData.keybindings
                $newExtDefault = Get-ProfileExtensions -profile $defaultData
                $newExtProfile = Get-ProfileExtensions -profile $profileData
                $newExt = @($newExtDefault) + @($newExtProfile) | Select-Object -Unique

                $profileData.settings = $newSettings
                $profileData.keybindings = $newKb
                $profileData.extensions = $newExt

                # Keep the same top-level properties structure
                $outputObj = @{
                    name = $profileData.name
                    settings = $profileData.settings
                    keybindings = $profileData.keybindings
                    extensions = $profileData.extensions
                }

                $outputObj | ConvertTo-Json -Depth 20 | Out-File -FilePath $file.FullName -Encoding UTF8
                Write-Color "Synchronized: $($file.Name)" "Green"
            } catch {
                Write-Color "Skipping invalid profile: $($file.Name)" "Yellow"
            }
        }
    }
    Write-Color "All profiles synchronized!`n" "Green"
}

function Interactive-Apply {
    $profileFiles = Get-ChildItem -Path $ProfilesDir -Filter "*.code-profile"
    if ($profileFiles.Count -eq 0) {
        Write-Color "No profiles found in $ProfilesDir" "Red"
        exit 1
    }

    Write-Color "`nWhich profile do you want to apply?" "Cyan"
    for ($i = 0; $i -lt $profileFiles.Count; $i++) {
        Write-Host "$($i + 1). $($profileFiles[$i].BaseName)"
    }
    
    $choice = Read-Host "Select a profile (number)"
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $profileFiles.Count) {
        Write-Color "Invalid selection." "Red"
        return
    }
    $chosenProfile = $profileFiles[$idx].BaseName

    Write-Color "`nDo you want to Sync or Replace?" "Cyan"
    Write-Host "1. Sync (Merges with current settings, keeps existing extensions)"
    Write-Host "2. Replace (Uninstalls all current extensions, overwrites settings)"
    
    $modeChoice = Read-Host "Select a mode (number)"
    $mode = ""
    if ($modeChoice -eq "1") { $mode = "sync" }
    elseif ($modeChoice -eq "2") { $mode = "replace" }
    else {
        Write-Color "Invalid selection." "Red"
        return
    }

    Apply-Profile -profileName $chosenProfile -mode $mode
}

while ($true) {
    Write-Color "`nWhat would you like to do?" "Cyan"
    Write-Host "1. Apply a Profile to VS Code"
    Write-Host "2. Sync all Profiles with Default Profile"
    Write-Host "3. Exit"
    $mainChoice = Read-Host "Select an action (number)"

    switch ($mainChoice) {
        "1" { Interactive-Apply }
        "2" { Sync-AllProfiles }
        "3" { Write-Host "Goodbye!"; exit 0 }
        Default { Write-Color "Invalid option" "Red" }
    }
}
