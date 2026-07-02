@echo off
setlocal

rem ============================================================
rem  dezip_recursif.bat
rem  Dezippe un fichier ZIP et tous les ZIP imbriques qu'il
rem  contient, automatiquement et sans aucune confirmation.
rem
rem  Fonctionnement en 2 phases :
rem    PHASE 1 : UN SEUL scan, au tout debut. Les zips imbriques
rem              sont ouverts en memoire (sans rien extraire),
rem              donc meme un zip dans un zip dans un zip est
rem              repere des le depart.
rem    PHASE 2 : extraction de TOUT en une seule fois. Les zips
rem              imbriques sont decompresses directement vers
rem              leur dossier final, sans ecrire de .zip
rem              intermediaire sur le disque.
rem
rem  Protection contre les noms en double :
rem    Rien n'est jamais ecrase. Dossier deja pris -> "nom (2)",
rem    fichier deja pris -> "photo (2).jpg", etc.
rem
rem  Utilisation :
rem    - Glisser-deposer un fichier .zip sur ce script, OU
rem    - En ligne de commande :
rem        dezip_recursif.bat "C:\chemin\vers\archive.zip"
rem
rem  Remarque : les zips imbriques sont lus en memoire. Pour des
rem  zips imbriques de plusieurs Go, prevoir assez de RAM.
rem ============================================================

rem --- Verification de l'argument ---
if "%~1"=="" (
    echo Utilisation : %~nx0 "chemin\vers\archive.zip"
    echo Vous pouvez aussi glisser-deposer un fichier .zip sur ce script.
    pause
    exit /b 1
)

if not exist "%~1" (
    echo ERREUR : fichier introuvable : "%~1"
    pause
    exit /b 1
)

if /I not "%~x1"==".zip" (
    echo ERREUR : "%~1" n'est pas un fichier .zip
    pause
    exit /b 1
)

rem Chemins passes a PowerShell via variables d'environnement
rem (aucun souci de guillemets ou d'apostrophes dans les noms).
set "SRC=%~f1"
set "DST=%~dpn1"
set "BATSELF=%~f0"

rem Le script PowerShell se trouve a la fin de ce fichier .bat,
rem apres le marqueur PSBEGIN. PowerShell lit ce fichier et
rem n'execute que cette partie.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$t=[IO.File]::ReadAllText($env:BATSELF); iex $t.Substring($t.IndexOf('#PS'+'BEGIN'))"

if errorlevel 1 (
    echo.
    echo ERREUR : echec de l'extraction.
    pause
    exit /b 1
)

echo.
pause
exit /b 0

rem ============================================================
rem  Tout ce qui suit est du PowerShell. cmd ne lit jamais ces
rem  lignes grace au "exit /b 0" ci-dessus.
rem ============================================================
#PSBEGIN
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$src  = $env:SRC
$dst0 = $env:DST

# Renvoie un chemin de dossier libre : "nom", sinon "nom (2)", "nom (3)"...
function DossierUnique([string]$b) {
    $c = $b; $i = 2
    while (Test-Path -LiteralPath $c) { $c = $b + ' (' + $i + ')'; $i++ }
    return $c
}

# Pareil pour un fichier, en gardant l'extension : "photo (2).jpg"
function FichierUnique([string]$b) {
    if (-not (Test-Path -LiteralPath $b)) { return $b }
    $dir = Split-Path -Parent $b
    $nom = [IO.Path]::GetFileNameWithoutExtension($b)
    $ext = [IO.Path]::GetExtension($b)
    $i = 2
    do { $c = Join-Path $dir ($nom + ' (' + $i + ')' + $ext); $i++ } while (Test-Path -LiteralPath $c)
    return $c
}

# ---------------- PHASE 1 : UN SEUL SCAN ----------------
# Les zips imbriques sont ouverts en memoire, rien n'est ecrit
# sur le disque pendant cette phase.
$script:nbFichiers = 0
$script:listeZips  = New-Object System.Collections.ArrayList

function Scan([IO.Stream]$flux, [string]$prefixe) {
    $arch = New-Object IO.Compression.ZipArchive($flux, [IO.Compression.ZipArchiveMode]::Read, $true)
    try {
        foreach ($e in $arch.Entries) {
            if ($e.FullName.EndsWith('/') -or $e.FullName.EndsWith('\')) { continue }
            $chemin = $prefixe + '\' + ($e.FullName -replace '/', '\')
            if ($e.FullName -match '\.zip$') {
                [void]$script:listeZips.Add($chemin)
                $ms = New-Object IO.MemoryStream
                $s = $e.Open(); $s.CopyTo($ms); $s.Dispose(); $ms.Position = 0
                try { Scan $ms ($chemin -replace '\.zip$', '') }
                catch { Write-Host ('  ATTENTION : zip illisible pendant le scan : ' + $chemin) }
                $ms.Dispose()
            } else {
                $script:nbFichiers++
            }
        }
    } finally { $arch.Dispose() }
}

Write-Host '=== PHASE 1 : scan unique (rien n''est encore extrait) ==='
Write-Host ('Archive : ' + $src)
$fs = [IO.File]::OpenRead($src)
Scan $fs ([IO.Path]::GetFileNameWithoutExtension($src))
$fs.Dispose()

Write-Host ('Scan termine : ' + $script:nbFichiers + ' fichier(s) et ' + $script:listeZips.Count + ' zip(s) imbrique(s).')
foreach ($z in $script:listeZips) { Write-Host ('  [ZIP] ' + $z) }

# ---------- PHASE 2 : EXTRACTION DE TOUT EN UNE FOIS ----------
# Les zips imbriques sont decompresses directement depuis la
# memoire vers leur dossier final : aucun .zip intermediaire
# n'est ecrit puis supprime, tout sort en un seul passage.

function Extraire([IO.Stream]$flux, [string]$dossier) {
    $arch = New-Object IO.Compression.ZipArchive($flux, [IO.Compression.ZipArchiveMode]::Read, $true)
    try {
        $racine = [IO.Path]::GetFullPath($dossier).TrimEnd('\') + '\'
        foreach ($e in $arch.Entries) {
            if ($e.FullName.EndsWith('/') -or $e.FullName.EndsWith('\')) { continue }
            $cible = [IO.Path]::GetFullPath((Join-Path $dossier ($e.FullName -replace '/', '\')))
            if (-not $cible.StartsWith($racine, [StringComparison]::OrdinalIgnoreCase)) {
                Write-Host ('  ATTENTION : entree ignoree (chemin suspect) : ' + $e.FullName)
                continue
            }
            if ($e.FullName -match '\.zip$') {
                $ms = New-Object IO.MemoryStream
                $s = $e.Open(); $s.CopyTo($ms); $s.Dispose(); $ms.Position = 0
                $sous = DossierUnique ($cible -replace '\.zip$', '')
                try { Extraire $ms $sous }
                catch {
                    # Zip illisible : on le copie tel quel pour ne rien perdre
                    $ms.Position = 0
                    $cible = FichierUnique $cible
                    $rep = Split-Path -Parent $cible
                    if (-not (Test-Path -LiteralPath $rep)) { New-Item -ItemType Directory -Path $rep -Force | Out-Null }
                    $out = [IO.File]::Open($cible, 'CreateNew')
                    $ms.CopyTo($out); $out.Dispose()
                    Write-Host ('  ERREUR : zip illisible, copie tel quel : ' + $e.FullName)
                }
                $ms.Dispose()
            } else {
                $cible = FichierUnique $cible
                $rep = Split-Path -Parent $cible
                if (-not (Test-Path -LiteralPath $rep)) { New-Item -ItemType Directory -Path $rep -Force | Out-Null }
                $out = [IO.File]::Open($cible, 'CreateNew')
                $s = $e.Open(); $s.CopyTo($out); $s.Dispose(); $out.Dispose()
            }
        }
    } finally { $arch.Dispose() }
}

Write-Host ''
Write-Host '=== PHASE 2 : extraction de tout en une seule fois ==='
$dest = DossierUnique $dst0
if ($dest -ne $dst0) { Write-Host ('Le dossier existe deja, pour ne rien ecraser tout ira dans : ' + $dest) }
$fs = [IO.File]::OpenRead($src)
Extraire $fs $dest
$fs.Dispose()

Write-Host ''
Write-Host 'Termine ! Tout le contenu a ete extrait dans :'
Write-Host ('  ' + $dest)
