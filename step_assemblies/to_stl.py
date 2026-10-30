"""Convertit chaque fichier STEP de ce dossier en STL (un STL par assemblage).

Usage : python to_stl.py
"""
from pathlib import Path

import cadquery as cq

HERE = Path(__file__).parent

for step in sorted(HERE.glob("*.step")):
    shape = cq.importers.importStep(str(step))
    stl = step.with_suffix(".stl")
    cq.exporters.export(shape, str(stl), tolerance=0.05, angularTolerance=0.1)
    print("écrit", stl)
