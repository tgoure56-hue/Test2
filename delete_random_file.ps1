[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Directory,

    [switch]$DryRun
)

if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
    Write-Error "'$Directory' n'est pas un repertoire."
    exit 1
}

$files = Get-ChildItem -LiteralPath $Directory -File -Recurse -Force -ErrorAction SilentlyContinue

if (-not $files -or $files.Count -eq 0) {
    Write-Error "Aucun fichier trouve dans '$Directory'."
    exit 1
}

$target = Get-Random -InputObject $files

if ($DryRun) {
    Write-Host "[dry-run] Serait supprime : $($target.FullName)"
    exit 0
}

try {
    Remove-Item -LiteralPath $target.FullName -Force -ErrorAction Stop
    Write-Host "Supprime : $($target.FullName)"
}
catch {
    Write-Error "Echec de la suppression de '$($target.FullName)' : $_"
    exit 1
}
