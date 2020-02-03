monster_web is the main pipeline code, and PDB.pm is the main PDB processing code

monster_web will take a PDB file, add hydrogens using WhatIf, then parses it.
The parsing code in PDB.pm attempts to find all hydrophobic and electrostatic contacts.

monster_web will then iterate through each model in the PDB file and run HBPlus and MSMS on them individually.
Finally, if there are multiple models, it'll compute averages and a summmary to display for all models.

I used a gfortran binary for mac os x from here:
https://github.com/fxcoudert/gfortran-for-macOS/releases

and compiled haad.f90 thus:
/usr/local/gfortran/bin/gfortran -o haad haad.f90 -ffree-line-length-512

you run haad thus:
./haad <pdb file>

and the output is a file of the same name with an additional *.h suffix
