#!/bin/bash

echo 'executing shell script with arg:' $*

#pipes the first argument to monster_web
su - monster -c "cd ~monster/NUMonster/perl_backend;./monster_web $1"

# echo 'current directory is:'
# pwd
#
# echo 'items in directory:'
# ls
