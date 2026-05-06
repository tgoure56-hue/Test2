#!/usr/bin/env python3
"""Supprime un fichier choisi aléatoirement dans un répertoire (récursivement)."""

import argparse
import os
import random
import sys


def collect_files(root: str) -> list[str]:
    files = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for name in filenames:
            files.append(os.path.join(dirpath, name))
    return files


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Supprime un fichier aléatoire dans un répertoire (récursif)."
    )
    parser.add_argument("directory", help="Répertoire cible")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Affiche le fichier qui serait supprimé sans le supprimer",
    )
    parser.add_argument(
        "--seed", type=int, default=None, help="Graine aléatoire (optionnel)"
    )
    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Erreur : '{args.directory}' n'est pas un répertoire.", file=sys.stderr)
        return 1

    if args.seed is not None:
        random.seed(args.seed)

    files = collect_files(args.directory)
    if not files:
        print(f"Aucun fichier trouvé dans '{args.directory}'.", file=sys.stderr)
        return 1

    target = random.choice(files)

    if args.dry_run:
        print(f"[dry-run] Serait supprimé : {target}")
        return 0

    try:
        os.remove(target)
    except OSError as exc:
        print(f"Échec de la suppression de '{target}' : {exc}", file=sys.stderr)
        return 1

    print(f"Supprimé : {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
