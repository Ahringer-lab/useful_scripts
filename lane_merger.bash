#!/bin/bash

#######################################################################################################
############################## Sequencing lane merger #################################################
# This script will merge fastq files from multiple lanes
# Inputs:
#           --dir   The directory where the fastq files are located, default is ~/data
#           --lanes The number of lanes to merge across, default is 2
#           --output Change the output directory, default is ~/output
# This script is run locally, it is not set up to run on the cluster
# The script can currently handle up to 4 lanes
# Author Steve Walsh May 20224
#######################################################################################################

#Set tht defaults

DIR=~/data
LANES=2
RUNID="Merged-$(date '+%Y-%m-%d-%R')"
OUTDIR=~/out
HELP="false"

function exit_with_bad_args {
    echo "Usage: bash lane_merger.bash optional args: --dir <input dir> --id <Run ID> --lanes <number of lanes> --output <output dir> "
    echo "Invalid arguments provided" >&2
    exit # this stops the terminal closing when run as source
}



#Set the possible input options
options=$(getopt -o '' -l input: -l id: -l lanes: -l output: -l help -- "$@") || exit_with_bad_args

#Get the inputs
eval set -- "$options"
while true; do
    case "$1" in
        --input)
            shift
            DIR="$1"
            ;;
        --id)
            shift
            RUNID="$1"
            ;;
        --lanes)
            shift
            LANES="$1"
            ;;
        --output)
            shift
            OUTDIR="$1"
            ;;
	--help)
            HELP="true"
            ;;
         --)
            shift
            break
            ;;
    esac
    shift
done

cd $DIR
OUTDIR=${OUTDIR}/${RUNID}
LOGFILE=${OUTDIR}/${RUNID}.log

#Check the lane numbers
if [[ $LANES < 2 ]]; then
    echo "Merging not required"
    exit 1
elif [[ $LANES > 4 ]]; then
    echo "Only implemented for up to 4 lanes"
    exit 1
fi

if [[ $HELP == "true" ]]; then
    echo "This script will merge fastq files from multiple lanes"
    echo
    echo "Inputs:"
    echo "--dir   The directory where the fastq files are located, default is ~/data"
    echo "--lanes The number of lanes to merge across, default is 2"
    echo "--output Change the output directory, default is ~/output"
    echo "--ID Change the ouput folder name"
    echo
    echo "This script is run locally, it is not set up to run on the cluster"
    echo  "The script can currently handle up to 4 lanes"
    exit 1
fi

mkdir $OUTDIR

#Make the log file, N.B log file only goes to 2 lanes at present
echo \#Run ID,${RUNID} > $LOGFILE
echo \# >> $LOGFILE

# Make array to store fastq name
declare -A FILES

#Get all fastq names from input folder
for f in *fastq.gz; do                  # search the files with the suffix
    base=${f%_L00*_*}                        # remove after "_L00*_" To make sample ID the hash key (Lane number is wildard here)
    if [[ $f == $base* ]] && [[ $f == *"R1"* ]]; then    # if the variable is the current sample ID and is forward
        FILES[$base]=$f                  # then store the filename
    elif [[ $f == $base* ]] && [[ $f == *"R2"* ]]; then # if the variable is the current sample and is reverse
        FILES[$base]+=" $f"
    fi
done

for base in "${!FILES[@]}"; do
    echo "${base}"

    if [[ $LANES == 2 ]]; then
    cat ${base}_L001_R1_001.fastq.gz ${base}_L002_R1_001.fastq.gz > ${OUTDIR}/${base}_merged_R1_001.fastq.gz
    cat ${base}_L001_R2_001.fastq.gz ${base}_L002_R2_001.fastq.gz > ${OUTDIR}/${base}_merged_R2_001.fastq.gz
    elif [[ $LANES == 3 ]]; then
    cat ${base}_L001_R1_001.fastq.gz ${base}_L002_R1_001.fastq.gz ${base}_L003_R1_001.fastq.gz > ${OUTDIR}/${base}_merged_R1_001.fastq.gz
    cat ${base}_L001_R2_001.fastq.gz ${base}_L002_R2_001.fastq.gz ${base}_L003_R2_001.fastq.gz > ${OUTDIR}/${base}_merged_R2_001.fastq.gz
    elif [[ $LANES == 4 ]]; then
    cat ${base}_L001_R1_001.fastq.gz ${base}_L002_R1_001.fastq.gz ${base}_L003_R1_001.fastq.gz ${base}_L004_R2_001.fastq.gz > ${OUTDIR}/${base}_merged_R1_001.fastq.gz
    cat ${base}_L001_R2_001.fastq.gz ${base}_L002_R2_001.fastq.gz ${base}_L003_R2_001.fastq.gz ${base}_L004_R2_001.fastq.gz > ${OUTDIR}/${base}_merged_R2_001.fastq.gz
    fi
    
    #Add read numbers to log file
    echo ${base}, >> $LOGFILE
    echo ${base}_L001_R1_001.fastq.gz
    echo ${base}_L001_R1_001.fastq.gz
    echo ${base}_L002_R1_001.fastq.gz
    echo ${base}_L002_R1_001.fastq.gz
    R1count_unmerged1=$(( $(gunzip -c ${base}_L001_R1_001.fastq.gz | wc -l)/4|bc ))
    R1count_unmerged2=$(( $(gunzip -c ${base}_L001_R2_001.fastq.gz | wc -l)/4|bc ))
    R2count_unmerged1=$(( $(gunzip -c ${base}_L002_R1_001.fastq.gz | wc -l)/4|bc ))
    R2count_unmerged2=$(( $(gunzip -c ${base}_L002_R2_001.fastq.gz | wc -l)/4|bc ))
    R1count_merged=$(( $(gunzip -c ${OUTDIR}/${base}_merged_R1_001.fastq.gz | wc -l)/4|bc ))
    R2count_merged=$(( $(gunzip -c ${OUTDIR}/${base}_merged_R1_001.fastq.gz | wc -l)/4|bc ))
    echo "Original counts" >> $LOGFILE
    echo ${R1count_unmerged1},${R1count_unmerged2}, >> $LOGFILE
    echo ${R2count_unmerged1},${R2count_unmerged2}, >> $LOGFILE
    echo "Merged Counts">> $LOGFILE
    echo ${R1count_merged}, >> $LOGFILE
    echo ${R2count_merged}, >> $LOGFILE
done
