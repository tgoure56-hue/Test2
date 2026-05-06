[CmdletBinding()]
param(
    [string]$Directory = "Z:\CAO\Workspace",
    [switch]$Run,
    [switch]$DryRun,
    [switch]$Uninstall
)

$TaskName = "RandomFileDeletion"
$ScriptPath = $PSCommandPath
if (-not $ScriptPath) { $ScriptPath = $MyInvocation.MyCommand.Path }

function Install-Task {
    param([string]$TargetDirectory)

    $argument = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`" -Run -Directory `"$TargetDirectory`""
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $argument
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
    Write-Host "Tache '$TaskName' installee. Elle s'executera a chaque ouverture de session."
    Write-Host "Cible : $TargetDirectory"
    Write-Host "Pour desinstaller : powershell -File `"$ScriptPath`" -Uninstall"
}

function Uninstall-Task {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Tache '$TaskName' desinstallee."
    }
    else {
        Write-Host "Aucune tache '$TaskName' trouvee."
    }
}

function Invoke-RandomDelete {
    param([string]$TargetDirectory, [switch]$Simulate)

    $tries = 0
    while (-not (Test-Path -LiteralPath $TargetDirectory -PathType Container) -and $tries -lt 15) {
        Start-Sleep -Seconds 2
        $tries++
    }

    if (-not (Test-Path -LiteralPath $TargetDirectory -PathType Container)) {
        Write-Error "'$TargetDirectory' n'est pas accessible."
        exit 1
    }

    $files = Get-ChildItem -LiteralPath $TargetDirectory -File -Recurse -Force -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) {
        Write-Error "Aucun fichier trouve dans '$TargetDirectory'."
        exit 1
    }

    $target = Get-Random -InputObject $files

    if ($Simulate) {
        Write-Host "[dry-run] Serait supprime : $($target.FullName)"
        return
    }

    try {
        Remove-Item -LiteralPath $target.FullName -Force -ErrorAction Stop
        Write-Host "Supprime : $($target.FullName)"
    }
    catch {
        Write-Error "Echec de la suppression de '$($target.FullName)' : $_"
        exit 1
    }
}

if ($Uninstall) {
    Uninstall-Task
    return
}

if ($Run) {
    Invoke-RandomDelete -TargetDirectory $Directory -Simulate:$DryRun
    return
}

# Mode par defaut : installation
Install-Task -TargetDirectory $Directory
