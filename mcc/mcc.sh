#!/usr/bin/env bash
# mcc files relevant to patch registration project.
#
# usage:
# mcc relpath1 relpath2
#
# where relpath are paths relative to ${PROJECT_PATH}
# Example:
# >$ ./mcc src/analysis/reg2stats src/scratch/registerBuckner

# prepare project and toolbox paths
# if want to make current: "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAIN_PATH="/data/vision/polina/users/adalca/patchRegistration"
PROJECT_PATH="${MAIN_PATH}/git"
TOOLBOX_PATH="/data/vision/polina/users/adalca/MATLAB/toolboxes"
EXTTOOLBOX_PATH="/data/vision/polina/users/adalca/MATLAB/external_toolboxes"

# MCC-related paths
MCCBUILD_PATH="${TOOLBOX_PATH}/mgt/src/mcc/" # mccBuild script path
MCC_RUN_DIR="/afs/csail.mit.edu/system/common/matlab/2013b/bin/mcc"

# need to add main path to system path (?).
export PATH="${MAIN_PATH}:$PATH"

## run mcc on desired (*.m) files.
for pfilename in $1 #"src/analysis/reg2stats" #"src/scratch/registerBuckner" #src/analysis/reg2stats
do
  filename=`basename ${pfilename}`

  # run via mccBuild.sh
  ${MCCBUILD_PATH}/mccBuild.sh \
    ${MCC_RUN_DIR} \
    ${PROJECT_PATH}/${pfilename}.m \
    ${MAIN_PATH}/MCC/MCC_${filename} \
    ${PROJECT_PATH}/src/ \
    ${PROJECT_PATH}/ext/ \
    ${TOOLBOX_PATH} \
    ${EXTTOOLBOX_PATH}
done
