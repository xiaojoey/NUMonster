HAAD:
https://pubmed.ncbi.nlm.nih.gov/19693270/
https://zhanglab.ccmb.med.umich.edu/HAAD/

I used a gfortran binary for mac os x from here:
https://github.com/fxcoudert/gfortran-for-macOS/releases

and compiled haad.f90 thus:
/usr/local/gfortran/bin/gfortran -o haad haad.f90 -ffree-line-length-512

you run haad thus:
./haad <pdb file>

and the output is a file of the same name with an additional *.h suffix

MSMS:
http://mgltools.scripps.edu/packages/MSMS/

We specifically use the `-buried` parameter to find
solvent-inaccessible interfaces between protein chains, and this is
only available in an old version of MSMS Dr. Michel Sanner compiled a
version of it for our server infrastructure, but its not downloadable
anywwhere. The option to explore the 'buried' interface is currently
available via the python bindings for the MSMS library.

