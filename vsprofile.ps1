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
    param ($profileFlag)
    Write-Color "Uninstalling all current extensions..." "Yellow"
    
    $cmd = if ($profileFlag -ne "") { "code $profileFlag --list-extensions" } else { "code --list-extensions" }
    $extList = iex $cmd
    
    foreach ($ext in $extList) {
        if ([string]::IsNullOrWhiteSpace($ext) -eq $false) {
            Write-Host "Uninstalling: $ext"
            if ($profileFlag -ne "") {
                $null = iex "code $profileFlag --uninstall-extension $ext --force"
            } else {
                $null = code --uninstall-extension $ext --force
            }
        }
    }
}

function Get-VSCodeProfilePath {
    param ($basePath, $profileName)
    if ($profileName -eq "Default") { return $basePath }
    
    $storageJson = Join-Path $basePath "globalStorage" "storage.json"
    # In WSL/Remote environments, storage.json might be shared or in a different location
    if (-not (Test-Path $storageJson)) {
        # Fallback for WSL targeting Windows
        if ($env:WSL_DISTRO_NAME) {
            $winAppData = cmd.exe /c "echo %APPDATA%" 2>$null
            if ($winAppData) {
                $storageJson = Join-Path ([System.IO.Path]::Combine((wslpath $winAppData.Trim()), "Code", "User")) "globalStorage" "storage.json"
            }
        }
    }
    
    if (-not (Test-Path $storageJson)) { return $null }
    
    try {
        $storage = Get-Content -Raw $storageJson | ConvertFrom-Json
        if ($null -eq $storage.userDataProfiles) { return $null }
        
        $profile = $storage.userDataProfiles | Where-Object { $_.name -eq $profileName }
        if ($null -eq $profile) { return $null }
        
        $uri = $profile.location
        if ($uri -match "^file://") {
            # Absolute URI
            $path = [System.Uri]::UnescapeDataString($uri).Replace("file:///", "")
            if ($path -match "^/[a-zA-Z]:") { $path = $path.Substring(1) }
            # If in WSL, convert Windows path
            if ($env:WSL_DISTRO_NAME -and $path -match "^[a-zA-Z]:") {
                $path = wslpath $path
            }
            return $path
        } else {
            # Relative location (relative to the User/profiles directory)
            return Join-Path $basePath "profiles" $uri
        }
    } catch {
        return $null
    }
}

function Apply-Profile {
    param ($profileName, $mode)
    
    $profileFile = Join-Path $ProfilesDir "$profileName.code-profile"
    $defaultFile = Join-Path $ProfilesDir "Default.code-profile"

    Write-Color "`nApplying Profile: $profileName in $mode mode..." "Cyan"
    
    $profileData = Get-Content -Raw -Path $profileFile | ConvertFrom-Json
    
    # Inherit from Default
    if ($profileName -ne "Default" -and (Test-Path $defaultFile)) {
        Write-Color "Merging with Default profile..." "Yellow"
        $defaultData = Get-Content -Raw -Path $defaultFile | ConvertFrom-Json
        
        $mergedSettings = Merge-Json -target $defaultData.settings -source $profileData.settings
        $mergedKb = Merge-Json -target $defaultData.keybindings -source $profileData.keybindings
        $defaultExts = Get-ProfileExtensions -profile $defaultData
        $profileExts = Get-ProfileExtensions -profile $profileData
        $mergedExts = @($defaultExts) + @($profileExts) | Select-Object -Unique

        $profileData = @{
            settings = $mergedSettings
            keybindings = $mergedKb
            extensions = $mergedExts
        }
    }

    # Detect native VS Code profile path
    $dataPath = $null
    while ($null -eq $dataPath) {
        $dataPath = Get-VSCodeProfilePath -basePath $UserDataPath -profileName $profileName
        
        if ($null -eq $dataPath) {
            Write-Host "`n" + ("=" * 60) -ForegroundColor Yellow
            Write-Color "⚠️  Profile '$profileName' not found in VS Code system." "Red"
            Write-Color "Recommended Action:" "Cyan"
            Write-Host " 1. Open VS Code."
            Write-Host " 2. Go to File > Profiles > New Profile..."
            Write-Host " 3. Create a profile exactly named: " -NoNewline
            Write-Host $profileName -ForegroundColor Green
            Write-Host ("=" * 60) -ForegroundColor Yellow
            
            $guideOptions = @("Profile Created -- Continue", "Exit")
            $profileChoice = Show-Menu -Title "`nWhat would you like to do?" -Options $guideOptions
            if ($profileChoice -eq 0) {
                Write-Color "Re-checking for profile..." "Cyan"
                continue
            } else {
                return
            }
        }
    }

    $settingsPath = Join-Path $dataPath "settings.json"
    $keybindingsPath = Join-Path $dataPath "keybindings.json"
    $profileFlag = if ($profileName -eq "Default") { "" } else { "--profile $profileName" }

    if ($mode -eq "replace") {
        Uninstall-AllExtensions -profileFlag $profileFlag

        $settingsToSave = if ($null -ne $profileData.settings) { $profileData.settings } else { @{} }
        $settingsToSave | ConvertTo-Json -Depth 20 | Out-File -FilePath $settingsPath -Encoding UTF8

        $kbToSave = if ($null -ne $profileData.keybindings -and $profileData.keybindings -is [array]) { $profileData.keybindings } else { @() }
        $kbToSave | ConvertTo-Json -Depth 20 | Out-File -FilePath $keybindingsPath -Encoding UTF8

        Write-Color "Settings and Keybindings replaced." "Green"
    } elseif ($mode -eq "sync") {
        $currentSettings = if (Test-Path $settingsPath) { Get-Content -Raw -Path $settingsPath | ConvertFrom-Json } else { @{} }
        $currentKb = if (Test-Path $keybindingsPath) { Get-Content -Raw -Path $keybindingsPath | ConvertFrom-Json } else { @() }
        
        $newSettings = Merge-Json -target $currentSettings -source $profileData.settings
        $newKb = Merge-Json -target $currentKb -source $profileData.keybindings

        $newSettings | ConvertTo-Json -Depth 20 | Out-File -FilePath $settingsPath -Encoding UTF8
        $newKb | ConvertTo-Json -Depth 20 | Out-File -FilePath $keybindingsPath -Encoding UTF8

        Write-Color "Settings and Keybindings merged safely." "Green"
    }

    Write-Color "Installing extensions for profile '$profileName'..." "Yellow"
    $exts = if ($profileData -is [hashtable]) { $profileData.extensions } else { Get-ProfileExtensions -profile $profileData }
    foreach ($ext in $exts) {
        if ([string]::IsNullOrWhiteSpace($ext) -eq $false) {
            Write-Host "Installing: $ext"
            if ($profileFlag -ne "") {
                $null = iex "code $profileFlag --install-extension $ext --force"
            } else {
                $null = code --install-extension $ext --force
            }
        }
    }

    Write-Color "Profile '$profileName' successfully applied!`n" "Green"
}

function Show-Menu {
    param($Title, $Options)
    $cur = 0
    Write-Color "`n$Title" "Cyan"
    
    $startCursorY = [console]::CursorTop
    $Host.UI.RawUI.CursorSize = 0 # Hide cursor if supported, ignore if not

    while ($true) {
        [console]::SetCursorPosition(0, $startCursorY)
        for ($i=0; $i -lt $Options.Count; $i++) {
            # Clear line
            Write-Host (" " * 80) -NoNewline
            [console]::SetCursorPosition(0, [console]::CursorTop)
            
            if ($i -eq $cur) {
                Write-Host "  > $($Options[$i])" -ForegroundColor Green
            } else {
                Write-Host "    $($Options[$i])"
            }
        }
        
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($key.VirtualKeyCode -eq 38) { # Up
            $cur--
            if ($cur -lt 0) { $cur = $Options.Count - 1 }
        } elseif ($key.VirtualKeyCode -eq 40) { # Down
            $cur++
            if ($cur -ge $Options.Count) { $cur = 0 }
        } elseif ($key.VirtualKeyCode -eq 13) { # Enter
            $Host.UI.RawUI.CursorSize = 25
            return $cur
        }
    }
}

function Interactive-Apply {
    $profileFiles = Get-ChildItem -Path $ProfilesDir -Filter "*.code-profile"
    if ($profileFiles.Count -eq 0) {
        Write-Color "No profiles found in $ProfilesDir" "Red"
        exit 1
    }

    $profileNames = @()
    foreach ($p in $profileFiles) { $profileNames += $p.BaseName }

    $idx = Show-Menu -Title "Which profile do you want to apply?" -Options $profileNames
    $chosenProfile = $profileNames[$idx]

    $modeOptions = @(
        "Sync (Merges with current settings, keeps existing extensions)",
        "Replace (Uninstalls all current extensions, overwrites settings)"
    )
    $modeIdx = Show-Menu -Title "Do you want to Sync or Replace?" -Options $modeOptions
    
    $mode = if ($modeIdx -eq 0) { "sync" } else { "replace" }

    Write-Host ""
    Apply-Profile -profileName $chosenProfile -mode $mode
}

while ($true) {
    $mainOptions = @(
        "Apply a Profile to VS Code",
        "Exit"
    )
    $mainIdx = Show-Menu -Title "What would you like to do?" -Options $mainOptions

    Write-Host ""
    if ($mainIdx -eq 0) { Interactive-Apply }
    elseif ($mainIdx -eq 1) { Write-Host "Goodbye!"; exit 0 }
}
