#!/bin/bash
# check that sge command (all jobs) ran correctly by looking for the right
# output files in each subfolder inside outpath
#
# usage:
# $ checkSgeRun outpath <type> <restart-missing>
# type can be "all" "registration" or "stats"
# restart is "true" or "false". if true, the respective sge job is restarted

##############################################################################
# setup existing options
##############################################################################
typeName=("registration" "stats")
checkFile=("/out/0_0.mat" "/out/stats.mat")
jobFile=("/sge/register.sh" "/sge/stats.sh")
nOptions="${#typeName[@]}"

##############################################################################
# parse inputs
##############################################################################
nInputs=$#
outpath=$1
if [ ${nInputs} -lt 2 ] ; then type="all"; else type="$2"; fi
if [ ${nInputs} -lt 3 ] ; then restart=false; else restart="$3"; fi


##############################################################################
# check runs
##############################################################################
# go through each folder in the output path
for file in `ls ${outpath}`
do

  # go through the different types
  for r in `seq 0 ${nOptions}`;
  do
    typec=${typeName[$r]} # type
    checkc=${checkFile[$r]} # file to check
    jobc=${jobFile[$r]} # file to re-run

    # process this option if selected
    if [ "${type}" = "all" ] || [ "${type}" = "${typec}" ] ; then

      # check if the right file exists
      if [ ! -f "${outpath}/${file}${checkc}" ]; then
        echo "${file} did not complete ${typec}"

        # restart job if indicated
        if $restart; then
          echo "Resubmitting ${typec} job for ${file}"
          #qsub "${outpath}/${file}${jobc}}"
        fi
      fi
    fi
  done
done
