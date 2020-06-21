#!/bin/sh
cd ..
rm *.o
make hbplus
cd test
../hbplus -f ./hbplus.opt AC.pdb > log
