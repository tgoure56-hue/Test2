"""Génère des fichiers STEP d'assemblage d'exemple avec CadQuery.

Usage : python generate.py  (les fichiers .step sont écrits dans ce dossier)
"""
import math
from pathlib import Path

import cadquery as cq

OUT = Path(__file__).parent


def bolt(d=8, length=30, head_h=5.5, head_d=13):
    head = cq.Workplane("XY").polygon(6, head_d).extrude(head_h)
    shank = cq.Workplane("XY").circle(d / 2).extrude(-length)
    return head.union(shank)


def nut(d=8, h=6.5, s=13):
    return cq.Workplane("XY").polygon(6, s).extrude(h).faces(">Z").workplane().hole(d)


# 1. Accouplement à brides : 2 arbres, 2 brides, 4 vis + 4 écrous
def flange_coupling():
    shaft_d, flange_d, flange_t, hub_d, hub_l, bcd = 20, 90, 12, 40, 25, 65

    def flange():
        f = (cq.Workplane("XY").circle(flange_d / 2).extrude(flange_t)
             .faces("<Z").workplane().circle(hub_d / 2).extrude(hub_l)
             .faces(">Z").workplane().hole(shaft_d)
             .faces(">Z").workplane()
             .polarArray(bcd / 2, 45, 360, 4).hole(8.5))
        return f

    shaft = cq.Workplane("XY").circle(shaft_d / 2).extrude(80)
    asm = cq.Assembly(name="accouplement_brides")
    asm.add(flange(), name="bride_A", color=cq.Color("steelblue"))
    asm.add(flange(), name="bride_B", color=cq.Color("steelblue"),
            loc=cq.Location((0, 0, 2 * flange_t), (1, 0, 0), 180))
    asm.add(shaft, name="arbre_A", color=cq.Color("gray"),
            loc=cq.Location((0, 0, -80 + flange_t)))
    asm.add(shaft, name="arbre_B", color=cq.Color("gray"),
            loc=cq.Location((0, 0, flange_t)))
    for i in range(4):
        a = math.radians(45 + 90 * i)
        x, y = bcd / 2 * math.cos(a), bcd / 2 * math.sin(a)
        asm.add(bolt(length=35), name=f"vis_M8_{i+1}", color=cq.Color("goldenrod"),
                loc=cq.Location((x, y, 2 * flange_t)))
        asm.add(nut(), name=f"ecrou_M8_{i+1}", color=cq.Color("goldenrod"),
                loc=cq.Location((x, y, -6.5)))
    return asm


# 2. Palier à semelle : socle, chapeau, roulement simplifié, arbre, 2 vis
def pillow_block():
    L, W, base_h, bore, axis_h = 140, 40, 15, 52, 45
    bore_cut = cq.Workplane("XZ").center(0, axis_h).circle(bore / 2).extrude(W, both=True)
    base = (cq.Workplane("XY").box(L, W, base_h, centered=(True, True, False))
            .faces(">Z").workplane().pushPoints([(-55, 0), (55, 0)]).hole(11)
            .union(cq.Workplane("XY").box(80, W, axis_h, centered=(True, True, False)))
            .cut(bore_cut)
            .cut(cq.Workplane("XY").pushPoints([(-30, 0), (30, 0)]).circle(4.5)
                 .extrude(20).translate((0, 0, axis_h - 20))))
    cap = (cq.Workplane("XY").box(80, W, 40, centered=(True, True, False))
           .translate((0, 0, axis_h)).edges("|Y and >Z").fillet(15)
           .cut(bore_cut)
           .cut(cq.Workplane("XY").pushPoints([(-30, 0), (30, 0)]).circle(4.5)
                .extrude(40).translate((0, 0, axis_h))))
    bearing_outer = (cq.Workplane("XZ").circle(bore / 2).circle(bore / 2 - 5)
                     .extrude(9, both=True))
    bearing_inner = (cq.Workplane("XZ").circle(bore / 2 - 9).circle(12.5)
                     .extrude(9, both=True))
    shaft = cq.Workplane("XZ").circle(12.5).extrude(70, both=True)

    asm = cq.Assembly(name="palier_semelle")
    asm.add(base, name="semelle", color=cq.Color("darkslategray"))
    asm.add(cap, name="chapeau", color=cq.Color("slategray"))
    asm.add(bearing_outer, name="roulement_bague_ext", color=cq.Color("gray80"),
            loc=cq.Location((0, 0, axis_h)))
    asm.add(bearing_inner, name="roulement_bague_int", color=cq.Color("gray80"),
            loc=cq.Location((0, 0, axis_h)))
    asm.add(shaft, name="arbre_25", color=cq.Color("gray"),
            loc=cq.Location((0, 0, axis_h)))
    for i, x in enumerate((-30, 30)):
        asm.add(bolt(length=30), name=f"vis_chapeau_{i+1}", color=cq.Color("goldenrod"),
                loc=cq.Location((x, 0, axis_h + 40)))
    return asm


# 3. Roulette pivotante : platine, chape, roue, axe, entretoises
def caster_wheel():
    plate = (cq.Workplane("XY").box(80, 80, 4).edges("|Z").fillet(6)
             .faces(">Z").workplane().rect(60, 60).vertices().hole(8))
    fork = (cq.Workplane("XY").box(50, 40, 4).translate((0, 0, -4))
            .union(cq.Workplane("XY").box(4, 40, 70).translate((-23, 0, -41)))
            .union(cq.Workplane("XY").box(4, 40, 70).translate((23, 0, -41)))
            .cut(cq.Workplane("YZ").center(0, -60).circle(5).extrude(30, both=True)))
    wheel = (cq.Workplane("YZ").circle(40).circle(5).extrude(15, both=True)
             .faces(">X").edges().fillet(3))
    tire = cq.Workplane("YZ").circle(46).circle(40).extrude(15, both=True)
    axle = cq.Workplane("YZ").circle(5).extrude(30, both=True)
    spacer = cq.Workplane("YZ").circle(9).circle(5).extrude(3.5)

    asm = cq.Assembly(name="roulette_pivotante")
    asm.add(plate, name="platine", color=cq.Color("gray40"), loc=cq.Location((0, 0, 2)))
    asm.add(fork, name="chape", color=cq.Color("gray40"))
    asm.add(wheel, name="jante", color=cq.Color("orange"), loc=cq.Location((0, 0, -60)))
    asm.add(tire, name="bandage", color=cq.Color("black"), loc=cq.Location((0, 0, -60)))
    asm.add(axle, name="axe", color=cq.Color("gray"), loc=cq.Location((0, 0, -60)))
    asm.add(spacer, name="entretoise_1", color=cq.Color("gray80"),
            loc=cq.Location((15, 0, -60)))
    asm.add(spacer, name="entretoise_2", color=cq.Color("gray80"),
            loc=cq.Location((-18.5, 0, -60)))
    return asm


if __name__ == "__main__":
    for fn in (flange_coupling, pillow_block, caster_wheel):
        a = fn()
        path = OUT / f"{a.name}.step"
        a.export(str(path))
        print("écrit", path, len(a.children), "pièces")
