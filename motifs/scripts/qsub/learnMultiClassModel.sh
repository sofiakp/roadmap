#!/bin/bash

usage()
{
cat <<EOF
usage: `basename $0` options FEATDIR 
Applies a multiclass model on a set of (binary) feature matrices.

By default, it will read all the *npz files in FEATDIR. These will
be concatenated and passed to a multiclass classification model. 
The model can be run with multiple regularization parameters, passed
using the -a option.

If you want to apply the multiclass model 
to a subset of the feature matrices, give a list of the corresponding
matrices using the -l argument. These will be assumed to be filenames
within FEATDIR.

The learned model will be written in
FEATDIR/<outpref>cd_a<alpha>_train${TRAIN}_model.pkl
<outpref> is the empty string by default, but can be changed with the -o option.

OPTIONS:
   -h     Show this message and exit
   -r NUM Fraction of examples used for training [Default: 0.8]
   -l STR List of files to which the multiclass model will be applied.
   -o STR Prefix for output model files.
   -a STR Comma separated list of alphas to use for training the multiclass model.
   -m NUM How many Gb of memory to request [Default: 8].
   -g     Use L1-LogisticRegression instead of L1/L2 hinge loss. 
See also createRuleMatrices.sh, getModelRules.py, applyRules.py, and the 
CDClassifier in the lightning Python library.

EOF
}

TRAIN=0.8
OUTPREF=""
ALPHAS="0.01"
FILELIST=
MEM=8
MAXFREQ=0.3
LOG=""
while getopts "hr:o:a:l:m:q:g" opt
do
    case $opt in
	h)
	    usage; exit;;
	r)
	    TRAIN=$OPTARG;;
	o)
	    OUTPREF=$OPTARG;;
	a)
	    ALPHAS=$OPTARG;;
	l)
	    FILELIST=$OPTARG;;
	m)
	    MEM=$OPTARG;;
	q) 
	    MAXFREQ=$OPTARG;;
	g)
	    LOG="--log";;
	?)
	    usage
            exit 1;;
    esac    
done

shift "$((OPTIND - 1))"
if [ $# -ne 1 ]; then 
    usage; exit 1;
fi

FEATDIR=$1

if [ ! -d ${FEATDIR}/tmp ]; then
    mkdir ${FEATDIR}/tmp
fi

SRCDIR="${LABHOME}/roadmap/src/motifs/"

IFS=',' 
read -a array <<< $ALPHAS

for a in "${array[@]}"; do
    if [[ $LOG == "--log" ]]; then
	pref=${OUTPREF}log_a${a}_train${TRAIN}_q${MAXFREQ}
    else
	pref=${OUTPREF}cd_a${a}_train${TRAIN}_q${MAXFREQ}
    fi
    outfile=${FEATDIR}/${pref}_model.pkl
    errfile=${FEATDIR}/tmp/${pref}.err
    ofile=${FEATDIR}/tmp/${pref}.out
    script=${FEATDIR}/tmp/${pref}.sh

    if [ -f $outfile ]; then
	echo "$outfile exists. Skipping." 1>&2
	continue
    fi

    echo "#!/bin/bash" > $script
    echo "module add python/2.7" >> $script
    echo "export PYTHONPATH=${HOME}/software/python/:$PYTHONPATH" >> $script
    params="--alpha $a --train $TRAIN --maxfreq $MAXFREQ $LOG"
    
    if [ -z $FILELIST ]; then
	echo "ls ${FEATDIR}/*.npz | python ${SRCDIR}/python/learnMulticlassModel.py $params $outfile" >> $script
    else
	echo "for f in \`cat $FILELIST\`; do echo ${FEATDIR}/\${f}; done | python ${SRCDIR}/python/learnMulticlassModel.py $params $outfile" >> $script
    fi
    if [[ $MEM -gt 16 ]]; then
	qsub -N $pref -P large_mem -q large -l h_vmem=${MEM}G -l h_rt=24:00:00 -e $errfile -o $ofile $script
    else
	qsub -N $pref -l h_vmem=${MEM}G -l h_rt=24:00:00 -e $errfile -o $ofile $script
    fi
done