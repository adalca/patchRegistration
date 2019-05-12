# create a PBDR config file from shell inputs and defaults.
#
# Note: PBDR should (or does?) take in individual config inputs that override 
# the options in the config file. However, in batch jobs, it is useful to 
# output a config file for each job or each batch. 
#
# getOpt type input specifying parameter values.
# These parameters match a standard config file list of inputs. 
# If a particular input is unspecified, we generate a default for that parameter
#   defaults are specified below.
#
# usage: 
#    prepPBRConfigFile.sh <options-see-below> OUTFILE
#
# general parameters
# -p --patchSize: patch size. Default: [5,5,5]
# -s --searchSize: total search region size (displacement cube). Default: [3,3,3]
# -g --gridSpacing: grid spacing. Default: [5, 5, 5]
# -i --nInnerReps: number of inner repetitions. Default: 3
# -v --verbose: verbosity (output). 0 for none, 1 for simple, 2 for complex/debug. Default: 1
#    --doaffine: whether to do affine before deformable. Default: false
#
# Hack options
#    --hack-adaptSearchGridSpace: whether to adapt search grid spacing in inner iterations. Default: false
# -k --hack-keepNodes: % of nodes to keep. Default: 100
# # NOT IN USE -t --hack-maxThr: hack for hyperintensity. Not sure if in use. #TODO
#
# Scale options
# -m --scale-method: method for scale function. (load or resize). Default: resize
# -S --scale-nScales: number of scales. Default: 4
#    --scale-minVolSize: when method is not load, the size of the smallest volume. Default: 16
#
# Warp options
# -d --warp-dir: warp direction Default: backward
# -r --warp-reg: warp regularization type Default: mrf
#    --warp-res: warp resolution at which to warp intermediate moving image 'full' or 'atscale'. Default: atscale. 
#
# Dist options
# -n --dist-nStates: ; type of patch search: 'complete' (all states) or # (look for top k states). Default: complete
# -M --dist-metric: 'euclidean' or 'seuclidean' or 'sparse'. Default: sparse
# -l --dist-location: distance location weight. Default: 0.001
#    --dist-libraryMethod: 'full' (memory intense but fast) or 'local' (slower but more memory-manageable). Default: local
#
# mrf options
#    --mrf-lambdaNode: mrf node weight. Default: 1 
# -e --mrf-lambdaEdge: mrf edge weight. Default: 0.1
#    --mrf-spatialPot: use local spatial neighbor potential. 'atscale' of 'full'. Default: full 
#    --mrf-fn: mrf function. @patchlib.patchmrf or @patchmrf_PR. Default:patchmrf_PR  
#    --mrf-inferMethod: @UGM_Infer_LBP or @UGM_Infer_MF or % @UGM_Infer_LBP_PR. Default: @UGM_Infer_LBP_PR 
#
# debug options
#    --debug-out. path for debug file. Example: /path/to/out/%d_%d.mat Default: <tempfile>%d_%d.mat

###############################################################################
# Defaults
###############################################################################

# prepare defaults
patchSize="[5, 5, 5]"
searchSize="[3, 3, 3]"
gridSpacing="[5, 5, 5]"
nInnerReps="3"
verbose="1"
doaffine="false"
# [hack]
hack_adaptSearchGridSpacing="false"
hack_keepNodes="100"
# [scale]
scale_method="load"
scale_nScales="4" 
scale_minVolSize="16"
# [warp]
warp_dir="backward"
warp_reg="mrf" 
warp_res="atscale"
# [dist]
dist_nStates="complete"
dist_metric="sparse"
dist_location="0.001"
dist_libraryMethod="local"
# [mrf]
mrf_lambda_node="1"
mrf_lambda_edge="0.1"
mrf_spatialPot="full"
mrf_fn="@patchmrf_PR" 
mrf_inferMethod="@UGM_Infer_LBP_PR" 
# [debug]
debug_out="`tempfile`%d_%d.mat"

###############################################################################
# Parse Options
###############################################################################

# reformat options with getopt
OPTS=`getopt -o p:s:g:i:v:k:m:S:d:r:n:l:e:M: -n 'parse-options' \
-long patchSize:,searchsize:,gridSpacing:,nInnerReps:,verbose:,doaffine:,\
hack-adaptSearchGridSpace:,hack-keepNodes:,\
scale-method:,scale-nScales:,scale-minVolSize:,\
warp-dir:,warp-reg:,warp-res:,\
dist-nStates:,dist-metric:,dist-location:,dist-libraryMethod:,\
mrf-lambdaNode:,mrf-lambdaEdge:,mrf-spatialPot:,mrf-fn:,mrf-inferMethod:,\
debug-out: -- "$@"`
if [ $? != 0 ] ; then
    exit 1
fi

eval set -- "$OPTS"

# options
while true ; do
    case "$1" in
        -p --patchSize ) patch size. Default: [5,5,5]

        # prepare defaults
        -p | --patchSize ) patchSize="$2"; shift 2;;
        -s | --searchSize ) searchSize="$2"; shift 2;;
        -g | --gridSpacing ) gridSpacing="$2"; shift 2;;
        -i | --nInnerReps ) nInnerReps="$2"; shift 2;;
        -v | --verbose ) verbose="$2"; shift 2;;
        --doaffine ) doaffine="$2"; shift 2;;
        # [hack]
        --hack-adaptSearchGridSpace ) hack_adaptSearchGridSpacing="$2"; shift 2;;
        -k | --hack-keepNodes ) hack_keepNodes="$2"; shift 2;;
        # [scale]
        -m | --scale-method ) scale_method="$2"; shift 2;;
        -S | --scale-nScales ) scale_nScales="$2"; shift 2;;
        --scale-minVolSize ) scale_minVolSize="$2"; shift 2;;
        # [warp]
        -d | --warp-dir ) warp_dir="$2"; shift 2;;
        -r | --warp-reg ) warp_reg="$2"; shift 2;;
        --warp-res ) warp_res="$2"; shift 2;;
        # [dist]
        -n | --dist-nStates ) dist_nStates="$2"; shift 2;;
        -M | --dist-metric ) dist_metric="$2"; shift 2;;
        -l | --dist-location ) dist_location="$2"; shift 2;;
        --dist-libraryMethod ) dist_libraryMethod="$2"; shift 2;;
        # [mrf]
        --mrf-lambdaNode ) mrf_lambda_node="$2"; shift 2;;
        -e | --mrf-lambdaEdge ) mrf_lambda_edge="$2"; shift 2;;
        --mrf-spatialPot ) mrf_spatialPot="$2"; shift 2;;
        --mrf-fn ) mrf_fn="$2"; shift 2;;
        --mrf-inferMethod ) mrf_inferMethod="$2"; shift 2;;
        # [debug]
        --debug-out ) debug_out="$2"; shift 2;;
        --) shift; break;;
    esac
done
# echo "Args:"
# for arg
# do
#     echo $arg
# done

###############################################################################
# Prepare output
###############################################################################

paramsinifile=$1;

echo "Parameters for $paramsinifile" >> ${paramsinifile}
# prepare defaults
echo "patchSize = $patchSize" >> ${paramsinifile}
echo "searchSize = $searchSize" >> ${paramsinifile}
echo "gridSpacing = $gridSpacing" >> ${paramsinifile}
echo "nInnerReps = $nInnerReps" >> ${paramsinifile}
echo "verbose = $verbose" >> ${paramsinifile}
echo "doaffine = $doaffine" >> ${paramsinifile}
# [hack]
echo "[hack]" >> ${paramsinifile}
echo "adaptSearchGridSpacing = ${hack_adaptSearchGridSpacing}" >> ${paramsinifile} 
echo "keepNodes = ${hack_keepNodes}" >> ${paramsinifile}
# [scale]
echo "[scale]" >> ${paramsinifile}
echo "method = ${scale_method}" >> ${paramsinifile}
echo "nScales = ${scale_nScales}" >> ${paramsinifile}
echo "minVolSize = ${scale_minVolSize}" >> ${paramsinifile}
# [warp]
echo "[warp]" >> ${paramsinifile}
echo "dir = ${warp_dir}" >> ${paramsinifile}
echo "reg = ${warp_reg}" >> ${paramsinifile}
echo "res = ${warp_res}" >> ${paramsinifile}
# [dist]
echo "[dist]" >> ${paramsinifile}
echo "nStats = ${dist_nStates}" >> ${paramsinifile}
echo "metric = ${dist_metric}" >> ${paramsinifile}
echo "location = ${dist_location}" >> ${paramsinifile}
echo "libraryMethod = ${dist_libraryMethod}" >> ${paramsinifile}
# [mrf]
echo "[mrf]" >> ${paramsinifile}
echo "lambda_node = ${mrf_lambda_node}" >> ${paramsinifile}
echo "lambda_edge = ${mrf_lambda_edge}" >> ${paramsinifile}
echo "spatialPot = ${mrf_spatialPot}" >> ${paramsinifile}
echo "fn = ${mrf_fn}" >> ${paramsinifile}
echo "inferMethod = ${mrf_inferMethod}" >> ${paramsinifile}
# [debug]
echo "[debug]" >> ${paramsinifile}
echo "out = ${debug_out}" >> ${paramsinifile}
