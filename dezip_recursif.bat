@echo off
setlocal

rem ============================================================
rem  dezip_recursif.bat
rem  Decompresse une archive RAR (ou ZIP / 7Z) et toutes les
rem  archives imbriquees qu'elle contient, automatiquement et
rem  sans aucune confirmation.
rem
rem  IMPORTANT : Windows ne sait pas ouvrir les .rar tout seul.
rem  Le script utilise 7-Zip (recommande, gratuit :
rem  https://www.7-zip.org) ou WinRAR, detecte automatiquement.
rem
rem  Fonctionnement :
rem    PHASE 1 : scan de l'archive au debut, affichage du contenu
rem              et de la liste des archives imbriquees visibles.
rem    PHASE 2 : extraction de tout, en cascade et d'un coup :
rem              chaque archive imbriquee est extraite dans son
rem              propre dossier puis supprimee, sans confirmation.
rem
rem  Protection contre les noms en double :
rem    Rien n'est jamais ecrase. Dossier deja pris -> "nom (2)".
rem
rem  Utilisation :
rem    - Glisser-deposer un fichier .rar (ou .zip / .7z) sur ce
rem      script, OU en ligne de commande :
rem        dezip_recursif.bat "C:\chemin\vers\archive.rar"
rem ============================================================

rem --- Verification de l'argument ---
if "%~1"=="" (
    echo Utilisation : %~nx0 "chemin\vers\archive.rar"
    echo Vous pouvez aussi glisser-deposer un fichier .rar sur ce script.
    pause
    exit /b 1
)

if not exist "%~1" (
    echo ERREUR : fichier introuvable : "%~1"
    pause
    exit /b 1
)

set "EXTOK="
if /I "%~x1"==".rar" set "EXTOK=1"
if /I "%~x1"==".zip" set "EXTOK=1"
if /I "%~x1"==".7z"  set "EXTOK=1"
if not defined EXTOK (
    echo ERREUR : "%~1" n'est pas une archive .rar, .zip ou .7z
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

$src  = $env:SRC
$dst0 = $env:DST

# Renvoie un chemin libre : "nom", sinon "nom (2)", "nom (3)"...
function DossierUnique([string]$b) {
    $c = $b; $i = 2
    while (Test-Path -LiteralPath $c) { $c = $b + ' (' + $i + ')'; $i++ }
    return $c
}

# ---------- Detection de l'outil d'extraction ----------
$sevenZip = $null
$unrar    = $null
foreach ($c in @("$env:ProgramFiles\7-Zip\7z.exe",
                 "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
                 "$env:ProgramW6432\7-Zip\7z.exe")) {
    if ($c -and (Test-Path -LiteralPath $c)) { $sevenZip = $c; break }
}
if (-not $sevenZip) {
    $cmd = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($cmd) { $sevenZip = $cmd.Source }
}
foreach ($c in @("$env:ProgramFiles\WinRAR\UnRAR.exe",
                 "${env:ProgramFiles(x86)}\WinRAR\UnRAR.exe")) {
    if ($c -and (Test-Path -LiteralPath $c)) { $unrar = $c; break }
}
if (-not $unrar) {
    $cmd = Get-Command unrar.exe -ErrorAction SilentlyContinue
    if ($cmd) { $unrar = $cmd.Source }
}

if ($sevenZip)   { Write-Host ('Outil utilise : 7-Zip  (' + $sevenZip + ')') }
elseif ($unrar)  { Write-Host ('Outil utilise : WinRAR (' + $unrar + ')') }

if (-not $sevenZip -and -not $unrar -and $src -notmatch '\.zip$') {
    Write-Host 'ERREUR : ni 7-Zip ni WinRAR n''a ete trouve sur ce PC.'
    Write-Host 'Windows ne sait pas ouvrir les .rar tout seul.'
    Write-Host 'Installez 7-Zip (gratuit) : https://www.7-zip.org'
    Write-Host 'puis relancez ce script.'
    exit 1
}

# Extrait une archive (rar/zip/7z) vers un dossier, sans confirmation.
# Leve une erreur si l'archive est illisible.
function ExtraireArchive([string]$archive, [string]$dest) {
    New-Item -ItemType Directory -Path $dest -Force | Out-Null
    if ($sevenZip) {
        # -y : oui a tout ; -aou : renomme si un nom existe deja
        & $sevenZip x -y -aou ('-o' + $dest) -- $archive | Out-Null
        if ($LASTEXITCODE -ne 0) { throw ('7-Zip a renvoye le code ' + $LASTEXITCODE) }
    } elseif ($archive -match '\.zip$') {
        Expand-Archive -LiteralPath $archive -DestinationPath $dest -Force
    } elseif ($unrar) {
        # -y : oui a tout ; -or : renomme si un nom existe deja
        & $unrar x -y -or -- $archive ($dest + '\') | Out-Null
        if ($LASTEXITCODE -ne 0) { throw ('UnRAR a renvoye le code ' + $LASTEXITCODE) }
    } else {
        throw 'aucun outil disponible pour ce format'
    }
}

# Liste le contenu d'une archive sans l'extraire (pour le scan).
function ListerArchive([string]$archive) {
    if ($sevenZip) {
        $sortie = & $sevenZip l -ba -slt -- $archive
        $chemin = $null
        foreach ($ligne in $sortie) {
            if ($ligne -like 'Path = *')        { $chemin = $ligne.Substring(7) }
            elseif ($ligne -like 'Folder = -')  { if ($chemin) { $chemin }; $chemin = $null }
            elseif ($ligne -like 'Folder = +')  { $chemin = $null }
        }
    } elseif ($archive -match '\.zip$') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
        $a = [IO.Compression.ZipFile]::OpenRead($archive)
        $a.Entries | Where-Object { $_.Name } | ForEach-Object { $_.FullName }
        $a.Dispose()
    } elseif ($unrar) {
        & $unrar lb -- $archive
    }
}

# ---------------- PHASE 1 : SCAN ----------------
Write-Host ''
Write-Host '=== PHASE 1 : scan de l''archive (rien n''est encore extrait) ==='
Write-Host ('Archive : ' + $src)
$entrees  = @(ListerArchive $src)
$imbriqueesVisibles = @($entrees | Where-Object { $_ -match '\.(rar|zip|7z)$' })
Write-Host ('Contenu : ' + $entrees.Count + ' element(s), dont ' + $imbriqueesVisibles.Count + ' archive(s) imbriquee(s) :')
foreach ($a in $imbriqueesVisibles) { Write-Host ('  [ARCHIVE] ' + $a) }
if ($imbriqueesVisibles.Count -gt 0) {
    Write-Host '(le contenu des archives imbriquees apparait apres leur extraction ;'
    Write-Host ' elles seront toutes traitees automatiquement en phase 2)'
}

# ---------- PHASE 2 : EXTRACTION DE TOUT ----------
Write-Host ''
Write-Host '=== PHASE 2 : extraction de tout, sans confirmation ==='
$dest = DossierUnique $dst0
if ($dest -ne $dst0) { Write-Host ('Le dossier existe deja, pour ne rien ecraser tout ira dans : ' + $dest) }
Write-Host ('Extraction de l''archive principale vers : ' + $dest)
ExtraireArchive $src $dest

# Archives imbriquees : extraites en cascade, chacune dans son
# propre dossier, puis supprimees. Se repete tant qu'il en reste
# (une archive peut en contenir d'autres).
do {
    $imbriquees = @(Get-ChildItem -LiteralPath $dest -Recurse -File |
                    Where-Object { $_.Extension -match '^\.(rar|zip|7z)$' })
    foreach ($a in $imbriquees) {
        $d = DossierUnique (Join-Path $a.DirectoryName $a.BaseName)
        Write-Host ('  Archive imbriquee : ' + $a.FullName)
        try {
            ExtraireArchive $a.FullName $d
            Remove-Item -LiteralPath $a.FullName -Force
        } catch {
            Write-Host ('  ERREUR : archive illisible, renommee en .echec : ' + $a.FullName)
            Move-Item -LiteralPath $a.FullName -Destination (DossierUnique ($a.FullName + '.echec'))
        }
    }
} while ($imbriquees.Count -gt 0)

Write-Host ''
Write-Host 'Termine ! Tout le contenu a ete extrait dans :'
Write-Host ('  ' + $dest)
