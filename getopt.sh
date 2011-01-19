#!/bin/bash - 
#===============================================================================
#
#          FILE:  getopt.sh
# 
#         USAGE:  ./getopt.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Omar Campagne (), ocampagne at gmail dot com
#       COMPANY: 
#       CREATED: 18/01/11 23:44:19 CET
#      REVISION:  ---
#===============================================================================

#!/bin/bash
echo "Before getopt"
for i
do
  echo $i
done
args=`getopt -o abc: -- "$@"`
eval set -- "$args"
echo "After getopt"
for i
do
  echo "-->$i"
done


