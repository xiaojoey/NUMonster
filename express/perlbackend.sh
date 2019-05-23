#!/bin/bash

#changes directory to the location of monster_web
cd ../perl_backend

echo 'executing shell script with arg:' $*

#pipes the first argument to monster_web
echo $1 | ./monster_web

echo 'current directory is:'
pwd

echo 'items in directory:'
ls
