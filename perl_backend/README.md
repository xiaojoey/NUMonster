monster_web is the main pipeline code, and PDB.pm is the main PDB processing code

monster_web will take a PDB file, add hydrogens using WhatIf, then parses it.
The parsing code in PDB.pm attempts to find all hydrophobic and electrostatic contacts.

monster_web will then iterate through each model in the PDB file and run HBPlus and MSMS on them individually.
Finally, if there are multiple models, it'll compute averages and a summmary to display for all models.
