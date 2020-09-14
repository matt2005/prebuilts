#!/bin/bash -e

# check for output files
DEPLOYFILECOUNT=ls -1 . | wc -l
if [ $DEPLOYFILECOUNT -ge 1 ]
then
echo "Done! Your image(s) should be in deploy/"
exit 0
else
echo "The script failed" >&2
exit 1
fi