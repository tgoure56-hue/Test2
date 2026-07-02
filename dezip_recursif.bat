@echo off
setlocal EnableDelayedExpansion

rem ============================================================
rem  dezip_recursif.bat
rem  Dezippe un fichier ZIP et tous les ZIP imbriques qu'il
rem  contient, automatiquement et sans aucune confirmation.
rem
rem  Utilisation :
rem    - Glisser-deposer un fichier .zip sur ce script, OU
rem    - En ligne de commande :
rem        dezip_recursif.bat "C:\chemin\vers\archive.zip"
rem
rem  Le contenu est extrait dans un dossier portant le nom de
rem  l'archive, a cote de celle-ci. Chaque ZIP imbrique est
rem  extrait dans son propre sous-dossier puis supprime.
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

set "SOURCE=%~f1"
set "DEST=%~dpn1"

rem --- Extraction de l'archive principale ---
echo.
echo Extraction de : "%SOURCE%"
echo Vers          : "%DEST%"
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%SOURCE%' -DestinationPath '%DEST%' -Force"
if errorlevel 1 (
    echo ERREUR : echec de l'extraction de l'archive principale.
    pause
    exit /b 1
)

rem --- Boucle : tant qu'il reste des ZIP imbriques, on les extrait ---
:boucle
set "TROUVE="
for /r "%DEST%" %%Z in (*.zip) do (
    set "TROUVE=1"
    echo Zip imbrique trouve : "%%~fZ"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%%~fZ' -DestinationPath '%%~dpnZ' -Force"
    if errorlevel 1 (
        rem On renomme le zip en echec pour ne pas boucler dessus a l'infini
        echo ERREUR : echec de l'extraction, fichier renomme en .zip.echec
        ren "%%~fZ" "%%~nxZ.echec"
    ) else (
        del /q "%%~fZ"
    )
)
if defined TROUVE goto boucle

echo.
echo Termine ! Tout le contenu a ete extrait dans :
echo   "%DEST%"
echo.
pause
exit /b 0
