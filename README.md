# Inventor Library Browser (add-in)

Add-in Autodesk Inventor (C# / .NET) qui ajoute un onglet **Library** au ruban.
Il permet de :

- parcourir et **rechercher** des composants dans une bibliothèque (dossiers de
  fichiers `.ipt` / `.iam`) ;
- **placer** directement le composant sélectionné dans l'assemblage actif ;
- si le composant n'est pas trouvé, **chercher sur TraceParts** (API partenaire,
  avec repli automatique sur le site web).

> ⚠️ Ce projet a été généré dans un environnement Linux : il **n'a pas pu être
> compilé ni testé contre Inventor**. Inventor est Windows-only. Ouvre la
> solution dans Visual Studio sur une machine Windows avec Inventor installé
> pour compiler, enregistrer et tester l'add-in.

## Structure

```
InventorLibraryAddin.sln
InventorLibraryAddin.addin        manifeste lu par Inventor au démarrage
src/
  InventorLibraryAddin.csproj
  StandardAddInServer.cs          point d'entrée COM + création du ruban
  Config/AddinSettings.cs         settings.json (dossiers, clé TraceParts)
  Library/LibraryIndex.cs         scan + recherche des fichiers
  Library/LibraryComponent.cs
  Placement/ComponentPlacer.cs    insertion d'occurrence dans l'assemblage
  TraceParts/TracePartsClient.cs  client HTTP configurable (voir [ADAPT])
  TraceParts/ITracePartsClient.cs
  TraceParts/TracePartsModels.cs
  Ui/LibraryBrowserWindow.xaml    fenêtre WPF
  Ui/LibraryBrowserViewModel.cs
  Ui/RelayCommand.cs
```

## Prérequis

- Windows + Autodesk Inventor (2022 ou plus récent).
- Visual Studio 2022 avec la charge « Développement .NET desktop ».
- .NET Framework 4.8 (Developer Pack).

## Compilation

1. Ouvre `InventorLibraryAddin.sln`.
2. Vérifie le chemin de l'interop Inventor. Par défaut, le `.csproj` pointe sur :
   `C:\Program Files\Autodesk\Inventor 2024\Bin\Public Assemblies`.
   Adapte la propriété `InventorPublicAssemblies` si ta version diffère, ou en
   ligne de commande :
   ```
   dotnet build -c Release -p:InventorPublicAssemblies="C:\Program Files\Autodesk\Inventor 2025\Bin\Public Assemblies"
   ```
3. Compile en `Release | x64`.

## Installation dans Inventor

L'add-in est un serveur COM : il doit être enregistré, et son manifeste `.addin`
copié là où Inventor le cherche.

1. **Enregistrement COM** (invite de commande **Administrateur**, regasm 64 bits) :
   ```
   "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\RegAsm.exe" /codebase src\bin\x64\Release\net48\InventorLibraryAddin.dll
   ```
2. **Manifeste** : copie `InventorLibraryAddin.addin` dans le dossier des add-ins
   d'Inventor, p.ex. :
   ```
   %APPDATA%\Autodesk\Inventor 2024\Addins\
   ```
   Vérifie que `<Assembly>` dans le `.addin` pointe vers la DLL (chemin absolu si
   nécessaire).
3. Relance Inventor. L'onglet **Library** apparaît dans l'environnement
   Assemblage.

## Configuration

Au premier lancement, un fichier de réglages est créé :

```
%APPDATA%\InventorLibraryAddin\settings.json
```

```json
{
  "LibraryFolders": ["D:\\Bibliotheque\\Standard", "D:\\Bibliotheque\\Achats"],
  "Extensions": [".ipt", ".iam"],
  "Recursive": true,
  "TracePartsBaseUrl": "https://api.traceparts.com",
  "TracePartsApiKey": ""
}
```

- `LibraryFolders` : les dossiers à indexer.
- `TracePartsApiKey` : ta clé d'API partenaire TraceParts. Si elle est vide, le
  bouton « Search TraceParts » ouvre directement le site web.

## Intégration TraceParts

Le client (`src/TraceParts/TracePartsClient.cs`) est volontairement générique.
Le contrat exact de l'API TraceParts (chemin d'endpoint, paramètres, schéma JSON)
dépend de ton compte partenaire. **Seules deux méthodes** marquées `[ADAPT]`
sont à ajuster :

- `BuildSearchRequestUri` — construire l'URL de recherche réelle ;
- `MapResponse` — mapper le JSON renvoyé vers `TracePartsResult`.

L'en-tête d'authentification (`Bearer` par défaut) est aussi à adapter au schéma
attendu par TraceParts.

## Utilisation

1. Ouvre ou crée un **assemblage** (`.iam`).
2. Onglet **Library** → **Library Browser**.
3. Tape un nom dans la recherche : la liste se filtre.
4. Sélectionne un composant → **Place selected component** (placé à l'origine).
5. Rien dans la bibliothèque ? **Search TraceParts** pour trouver une référence,
   puis **Open in browser** pour la page du composant.
