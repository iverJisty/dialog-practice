#!/bin/sh


ls -aRl | grep -v '^d' | awk '{print $5, $9}' | sort -rn -k 1 | head -5 | awk 'BEGIN{n=1;}{print n ":" $0; n++ }'

echo -n "Dir num  : "
printf "\t%s\n" $(ls -aFRl |  awk '!/\.\.\// && !/\.\// && /^d/ { print $9 }'  | wc -l)

echo -n "File num : "
printf "\t%s\n" $(ls -aRl | grep '^-' | wc -l)

echo -n "Total    : "
printf "\t%s\n" $(ls -aFRl | grep -v '^d' | awk '{s += $5} END {print s}')


