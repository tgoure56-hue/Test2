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
rem    PHASE 1 : scan de l'archive au debut, liste des archives
rem              imbriquees reperees.
rem    PHASE 2 : extraction A PLAT : TOUS les fichiers vont dans
rem              UN SEUL dossier, sans aucun sous-dossier. Les
rem              archives imbriquees sont extraites EN PARALLELE
rem              (plusieurs a la fois) pour aller au plus vite,
rem              puis supprimees.
rem
rem  Noms en double : rien n'est jamais ecrase. En cas de
rem  doublon le fichier est renomme automatiquement par l'outil
rem  (ex : "photo_1.jpg" avec 7-Zip, "photo(2).jpg" avec WinRAR).
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

if ($sevenZip)  { Write-Host ('Outil utilise : 7-Zip  (' + $sevenZip + ')') }
elseif ($unrar) { Write-Host ('Outil utilise : WinRAR (' + $unrar + ')') }

if (-not $sevenZip -and -not $unrar -and $src -notmatch '\.zip$') {
    Write-Host 'ERREUR : ni 7-Zip ni WinRAR n''a ete trouve sur ce PC.'
    Write-Host 'Windows ne sait pas ouvrir les .rar tout seul.'
    Write-Host 'Installez 7-Zip (gratuit) : https://www.7-zip.org'
    Write-Host 'puis relancez ce script.'
    exit 1
}

# Extraction .zip a plat sans outil externe (solution de secours)
function ExtraireZipFlatNet([string]$zip, [string]$dest) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    $a = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        foreach ($e in $a.Entries) {
            if (-not $e.Name) { continue }
            $base = [IO.Path]::GetFileNameWithoutExtension($e.Name)
            $ext  = [IO.Path]::GetExtension($e.Name)
            $cible = Join-Path $dest $e.Name
            $i = 2
            while (Test-Path -LiteralPath $cible) {
                $cible = Join-Path $dest ($base + ' (' + $i + ')' + $ext); $i++
            }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($e, $cible, $false)
        }
    } finally { $a.Dispose() }
}

# Extrait une archive A PLAT (commande "e" : fichiers seulement,
# aucun dossier recree) vers $dest, sans confirmation.
# 7-Zip : -aou renomme les doublons / UnRAR : -or pareil.
function ExtraireAPlat([string]$archive, [string]$dest) {
    if ($sevenZip) {
        & $sevenZip e -y -aou -mmt=on -bso0 -bse0 -bsp0 ('-o' + $dest) -- $archive
        if ($LASTEXITCODE -ne 0) { throw ('7-Zip a renvoye le code ' + $LASTEXITCODE) }
    } elseif ($archive -match '\.zip$') {
        ExtraireZipFlatNet $archive $dest
    } elseif ($unrar) {
        # UnRAR extrait dans le dossier courant : on s'y place
        Push-Location -LiteralPath $dest
        try {
            & $unrar e -y -or -idq -- $archive
            if ($LASTEXITCODE -ne 0) { throw ('UnRAR a renvoye le code ' + $LASTEXITCODE) }
        } finally { Pop-Location }
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
            if ($ligne -like 'Path = *')       { $chemin = $ligne.Substring(7) }
            elseif ($ligne -like 'Folder = -') { if ($chemin) { $chemin }; $chemin = $null }
            elseif ($ligne -like 'Folder = +') { $chemin = $null }
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

# Extrait toute une vague d'archives EN PARALLELE (une extraction
# par coeur du processeur maximum), toutes vers le meme dossier.
# Archive reussie -> supprimee ; illisible -> renommee .echec.
function ExtraireVagueParallele([array]$archives, [string]$dest) {
    $cap = [Environment]::ProcessorCount
    $lances = @()
    foreach ($a in $archives) {
        $viaOutil = $false
        if ($sevenZip) { $viaOutil = $true }
        elseif ($unrar -and $a.Extension -ne '.zip') { $viaOutil = $true }

        if (-not $viaOutil) {
            # .zip sans 7-Zip : extraction .NET directe (non parallele)
            try {
                ExtraireZipFlatNet $a.FullName $dest
                Remove-Item -LiteralPath $a.FullName -Force
            } catch {
                Write-Host ('  ERREUR : illisible, renomme en .echec : ' + $a.Name)
                Move-Item -LiteralPath $a.FullName -Destination (DossierUnique ($a.FullName + '.echec'))
            }
            continue
        }

        while (@($lances | Where-Object { -not $_.Proc.HasExited }).Count -ge $cap) {
            Start-Sleep -Milliseconds 50
        }

        if ($sevenZip) {
            $argu = 'e -y -aou -mmt=on -bso0 -bse0 -bsp0 "-o' + $dest + '" -- "' + $a.FullName + '"'
            $p = Start-Process -FilePath $sevenZip -ArgumentList $argu -WindowStyle Hidden -PassThru
        } else {
            $argu = 'e -y -or -idq -- "' + $a.FullName + '"'
            $p = Start-Process -FilePath $unrar -ArgumentList $argu -WorkingDirectory $dest -WindowStyle Hidden -PassThru
        }
        $lances += ,@{ Proc = $p; Archive = $a }
    }
    foreach ($x in $lances) {
        $x.Proc.WaitForExit()
        if ($x.Proc.ExitCode -eq 0) {
            Remove-Item -LiteralPath $x.Archive.FullName -Force
        } else {
            Write-Host ('  ERREUR : illisible, renomme en .echec : ' + $x.Archive.Name)
            Move-Item -LiteralPath $x.Archive.FullName -Destination (DossierUnique ($x.Archive.FullName + '.echec'))
        }
    }
}

# ---------------- PHASE 1 : SCAN ----------------
Write-Host ''
Write-Host '=== PHASE 1 : scan de l''archive (rien n''est encore extrait) ==='
Write-Host ('Archive : ' + $src)
$entrees = @(ListerArchive $src)
$imbriqueesVisibles = @($entrees | Where-Object { $_ -match '\.(rar|zip|7z)$' })
Write-Host ('Contenu : ' + $entrees.Count + ' element(s), dont ' + $imbriqueesVisibles.Count + ' archive(s) imbriquee(s) :')
foreach ($a in $imbriqueesVisibles) { Write-Host ('  [ARCHIVE] ' + $a) }

# ---------- PHASE 2 : EXTRACTION A PLAT, TOUT D'UN COUP ----------
Write-Host ''
Write-Host '=== PHASE 2 : extraction de tout, a plat, sans confirmation ==='
$dest = DossierUnique $dst0
New-Item -ItemType Directory -Path $dest -Force | Out-Null
Write-Host ('TOUS les fichiers vont dans un seul dossier : ' + $dest)

ExtraireAPlat $src $dest

do {
    # Tout est a plat dans $dest : pas besoin de chercher dans des
    # sous-dossiers. On extrait chaque vague d'archives en parallele.
    $restantes = @(Get-ChildItem -LiteralPath $dest -File |
                   Where-Object { $_.Extension -match '^\.(rar|zip|7z)$' })
    if ($restantes.Count -gt 0) {
        Write-Host ('  ' + $restantes.Count + ' archive(s) imbriquee(s) -> extraction en parallele...')
        ExtraireVagueParallele $restantes $dest
    }
} while ($restantes.Count -gt 0)

$total = @(Get-ChildItem -LiteralPath $dest -File).Count
Write-Host ''
Write-Host ('Termine ! ' + $total + ' fichier(s), tous dans le dossier :')
Write-Host ('  ' + $dest)
