# HBPlus

Below is old text that was saved to describe changes made to improve
hydrogen bond testing

```updated:

necatm: include O' and O'' for every standard AA
accepts: 2 for above in right place
nbonds: +2 to every number
resbonds: C O' : C O'' added for every standard AA

NOT updated:
donors: O doesnt donate h-bonds
'*' in NAs, further testing needed to see if necessary

*HO2 not realised/understood
H5T/H3T neither```

Below are simple steps for compiling and running hbplus

```
$ make clean
$ make hbplus
$ ./hbplus -f hbplus.opt test/AC.pdb > test/log
```