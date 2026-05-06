@@@echo off
@@findstr /b /v "^@@" "%~f0" | powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:RDF_SCRIPT='%~f0'; & ([scriptblock]::Create([Console]::In.ReadToEnd())) @args" %*
@@exit /b %errorlevel%

param(
    [string]$Directory = "Z:\CAO\Workspace",
    [switch]$Run,
    [switch]$DryRun,
    [switch]$Uninstall
)

$ScriptPath = $env:RDF_SCRIPT
$TaskName = "RandomFileDeletion"

function Install-Task {
    $psCommand = @"
`$env:RDF_SCRIPT = '$ScriptPath'
`$lines = Get-Content -LiteralPath '$ScriptPath' | Where-Object { `$_ -notmatch '^@@' }
& ([scriptblock]::Create((`$lines -join [Environment]::NewLine))) -Run -Directory '$Directory'
"@
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($psCommand))
    $argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -EncodedCommand $encoded"

    $action   = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument
    $trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null

    Write-Host ""
    Write-Host "OK : tache '$TaskName' installee."
    Write-Host "Cible       : $Directory"
    Write-Host "Declencheur : ouverture de session de $env:USERNAME"
    Write-Host "Source      : $ScriptPath"
    Write-Host ""
    Write-Host "Pour desinstaller, ouvrez cmd et lancez :"
    Write-Host "  `"$ScriptPath`" -Uninstall"
    Write-Host ""
    Read-Host "Appuyez sur Entree pour fermer"
}

function Uninstall-Task {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Tache '$TaskName' desinstallee."
    } else {
        Write-Host "Aucune tache '$TaskName' trouvee."
    }
    Read-Host "Appuyez sur Entree pour fermer"
}

function Invoke-RandomDelete {
    param([string]$TargetDirectory, [switch]$Simulate)

    $tries = 0
    while (-not (Test-Path -LiteralPath $TargetDirectory -PathType Container) -and $tries -lt 15) {
        Start-Sleep -Seconds 2
        $tries++
    }
    if (-not (Test-Path -LiteralPath $TargetDirectory -PathType Container)) { return }

    $files = Get-ChildItem -LiteralPath $TargetDirectory -File -Recurse -Force -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) { return }

    $target = Get-Random -InputObject $files
    if ($Simulate) {
        Write-Host "[dry-run] Serait supprime : $($target.FullName)"
        return
    }
    try {
        Remove-Item -LiteralPath $target.FullName -Force -ErrorAction Stop
    } catch { }
}

if ($Uninstall) { Uninstall-Task; return }
if ($Run)       { Invoke-RandomDelete -TargetDirectory $Directory -Simulate:$DryRun; return }

Install-Task
