@echo off
setlocal

rem ============================================================
rem  dezip_recursif.bat
rem  Dezippe un fichier ZIP et tous les ZIP imbriques qu'il
rem  contient, automatiquement et sans aucune confirmation.
rem
rem  Fonctionnement par passes :
rem    1. Extraction de l'archive principale
rem    2. Scan complet du contenu : liste de TOUS les zips trouves
rem    3. Extraction de toute la liste d'un coup
rem    4. Nouveau scan complet (au cas ou les zips extraits
rem       contenaient eux-memes des zips), et ainsi de suite
rem       jusqu'a ce qu'il ne reste plus aucun zip.
rem
rem  Protection contre les noms en double :
rem    Chaque zip est extrait dans un dossier a son nom. Si ce
rem    dossier existe deja, le script n'ecrase RIEN : il extrait
rem    dans "nom (2)", "nom (3)", etc.
rem
rem  Utilisation :
rem    - Glisser-deposer un fichier .zip sur ce script, OU
rem    - En ligne de commande :
rem        dezip_recursif.bat "C:\chemin\vers\archive.zip"
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

rem Les chemins sont passes a PowerShell via des variables
rem d'environnement pour eviter tout probleme de guillemets
rem ou d'apostrophes dans les noms de fichiers.
set "SRC=%~f1"
set "DST=%~dpn1"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; function CheminUnique([string]$b){ $c=$b; $i=2; while(Test-Path -LiteralPath $c){ $c=$b + ' (' + $i + ')'; $i++ }; return $c }; $src=$env:SRC; $dest=CheminUnique $env:DST; if($dest -ne $env:DST){ Write-Host ('Le dossier existe deja, pour ne rien ecraser l''extraction ira dans : ' + $dest) }; Write-Host ('Extraction de l''archive principale :'); Write-Host ('  ' + $src); Write-Host ('Vers : ' + $dest); Expand-Archive -LiteralPath $src -DestinationPath $dest -Force; $passe=0; do { $zips=@(Get-ChildItem -LiteralPath $dest -Recurse -Filter *.zip -File); if($zips.Count -gt 0){ $passe++; Write-Host ''; Write-Host ('=== Passe ' + $passe + ' : scan termine, ' + $zips.Count + ' zip(s) imbrique(s) detecte(s) ==='); foreach($z in $zips){ Write-Host ('  - ' + $z.FullName) }; Write-Host 'Extraction de toute la liste...'; foreach($z in $zips){ $d=CheminUnique (Join-Path $z.DirectoryName $z.BaseName); if($d -ne (Join-Path $z.DirectoryName $z.BaseName)){ Write-Host ('  Nom deja pris, extraction dans : ' + $d) }; try { Expand-Archive -LiteralPath $z.FullName -DestinationPath $d -Force; Remove-Item -LiteralPath $z.FullName -Force } catch { Write-Host ('  ERREUR sur ' + $z.FullName + ' (renomme en .echec)'); Move-Item -LiteralPath $z.FullName -Destination (CheminUnique ($z.FullName + '.echec')) } } } } while($zips.Count -gt 0); Write-Host ''; Write-Host ('Termine ! Tout le contenu a ete extrait dans :'); Write-Host ('  ' + $dest)"

if errorlevel 1 (
    echo.
    echo ERREUR : echec de l'extraction.
    pause
    exit /b 1
)

echo.
pause
exit /b 0
