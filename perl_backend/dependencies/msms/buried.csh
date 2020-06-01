#! /bin/csh -f
#	Shell script to run msms program to compute buried surfaces
#

if (! (-e $1:r.xyzr) ) then
	echo Missing input file: $1:r.xyzr
	exit
else if (! (-e $2:r.xyzr) ) then
	echo  Missing input file: $2:r.xyzr
	exit
endif

if ($3 == '') then
	set density = 19
else	
	set density = $3
endif

set BASE2 = `basename $2`
set OF = $1:rct$BASE2:r_$density
echo $OF
echo
echo Computing surface of $1:r buried by $2:r -- density = $density
echo Running MSMS....

echo Surface of $1:r buried by $2:r -- density = $density > $OF.log
/home/monster/execs/msms/msms -density $density -probe_radius 1.4 \
	-if $1:r.xyzr -buried $2:r.xyzr \
	-of $OF >> $OF.log 

awk '/surface/ && /vertices/'  $OF.log

echo
echo Analyzing buried surface... 
if ( !(-e $1:r.pdb) ) then
	echo Missing PDB file $1:r.pdb
else
	grep "buried SES" $OF.log > $OF.anal
	/home/monster/execs/msms/vert2residues $1:r.pdb $OF.vert >> $OF.anal
endif
echo Done. Wrote AVS fld files and surface analysis files $OF
