#!/bin/bash
# check that sge command (all jobs) ran correctly by looking for the right
# output files in each subfolder inside outpath
#
# usage:
# $ checkSgeRun outfolders <type> <restart-missing>
# type can be "all" "registration" or "stats"
# restart is "true" or "false". if true, the respective sge job is restarted
#
# example:
# $ /path/toscript/checkSgeRun '/path/to/output/*' stats false

##############################################################################
# setup existing options
##############################################################################
typeName=("registration" "stats")
checkFile=("/out/0_0.mat" "/out/stats.mat")
jobFile=("/sge/register.sh" "/sge/reg2stats.sh")
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
for file in `ls ${outpath} -d`
do
  foldername=`basename ${file}`

  # go through the different types
  maxSeq=`expr ${nOptions} - 1`
  for r in `seq 0 ${maxSeq}`;
  do
    typec=${typeName[$r]} # type
    checkc=${checkFile[$r]} # file to check
    jobc=${jobFile[$r]} # file to re-run

    # process this option if selected
    if [ "${type}" = "all" ] || [ "${type}" = "${typec}" ] ; then

      # check if the right file exists
      if [ ! -f "${file}${checkc}" ]; then
        echo "${foldername} did not complete ${typec}."

        # restart job if indicated
        if $restart; then
          echo "Resubmitting ${typec} job for ${foldername}."
          qsub "${file}${jobc}"
        fi
      fi
    fi
  done
done
