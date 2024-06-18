#!/bin/bash
#SBATCH --job-name=RNASeq  
#SBATCH --nodes=1
#SBATCH --ntasks=3
#SBATCH --cpus-per-task=6 
#SBATCH --mem=15gb
#SBATCH --output=pipeline_%j.log # Standard output and error log

INPUT=~/data
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
            INPUT="$1"
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

if [[ $HELP == "true" ]]; then
    echo "This script will merge fastq files from multiple lanes"
    echo
    echo "Inputs:"
    echo "--dir   The directory where the fastq files are located, default is ~/data"
    echo "--lanes The number of lanes to merge across, default is 2"
    echo "--output Change the output directory, default is ~/output"
    echo "--ID Change the ouput folder name"
    echo
    echo "This is an sbatch script to run on the hpc"
    echo  "The script can currently handle up to 4 lanes"
    exit 1
fi

srun --mem=10000MB --ntasks=1 ./lane_merger.bash --input ${INPUT} --id ${RUNID} --lane ${LANES} --output ${OUTDIR}