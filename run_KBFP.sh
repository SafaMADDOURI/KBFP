#!/bin/sh
#PBS -l select=1:ncpus=2:mem=50gb
#PBS -l walltime=36:00:00
#PBS -V

# Variables
INDEX_DIR="/store/EQUIPES/SSFA/MEMBERS/safa.maddouri/KBFP/index_RS/IndexKamrat_20mer"
SCRIPTS_DIR="/store/EQUIPES/SSFA/MEMBERS/safa.maddouri/kmerBasedFramePedictor/SCRIPTS"
FILES_DIR="/store/EQUIPES/SSFA/MEMBERS/safa.maddouri/kmerBasedFramePedictor/RESULTS"
SIF_FILE="/store/EQUIPES/SSFA/daniel.shared/Bin/KaMRaT.sif"
FASTA_FILE="/store/EQUIPES/SSFA/MEMBERS/safa.maddouri/kmerBasedFramePedictor/sequences.fasta"

# Arguments
PHASE_SHIFT="+1"  # Phase shift to use
KMER_LENGTH="20"  # Length of k-mers

# Initialization
cd ${PBS_O_WORKDIR}
source /home/safa.maddouri/miniconda3/bin/activate
mkdir -p "$FILES_DIR"

# KaMRat query
apptainer exec --bind '/store:/store' -B '/data:/data' $SIF_FILE kamrat query -idxdir $INDEX_DIR -fasta $FASTA_FILE -toquery median -withabsent -outpath "$FILES_DIR/out"

# Add ID to output
python3 "$SCRIPTS_DIR/addid.py" "$FASTA_FILE" "$FILES_DIR/out" "$FILES_DIR/QuerySeqInRS.tsv"

# Get the header from the OUTPUT_FILE
HEADER=$(head -n 1 "$FILES_DIR/QuerySeqInRS.tsv")

# Filter RS+/RS- with the exact header from OUTPUT_FILE
{
    # Add header to RS+ file
    echo -e "$HEADER" > "$FILES_DIR/RS+"
    awk -F'\t' 'NR > 1 {
        sum = 0;
        for(i=3; i<=NF; i++) sum += $i;
        if(sum != 0) print
    }' "$FILES_DIR/QuerySeqInRS.tsv" >> "$FILES_DIR/RS+"
    
    # Add header to RS- file
    echo -e "$HEADER" > "$FILES_DIR/RS-"
    awk -F'\t' 'NR > 1 {
        sum = 0;
        for(i=3; i<=NF; i++) sum += $i;
        if(sum == 0) print
    }' "$FILES_DIR/QuerySeqInRS.tsv" >> "$FILES_DIR/RS-"
}

# Create RS+/RS- Fasta files
awk 'NR > 1 {print ">"$1"\n"$2}' "$FILES_DIR/RS+" > "$FILES_DIR/RS+.fa"
awk 'NR > 1 {print ">"$1"\n"$2}' "$FILES_DIR/RS-" > "$FILES_DIR/RS-.fa"

# Use the k-mer length $KMER_LENGTH
python3 "$SCRIPTS_DIR/generate_kmers_fromFasta.py" "$FILES_DIR/RS+.fa" "$FILES_DIR/kmersFromContigs.fa" "$KMER_LENGTH"

# KaMRat query on the generated kmers
apptainer exec --bind /store/EQUIPES/SSFA/MEMBERS/safa.maddouri $SIF_FILE kamrat query -idxdir "$INDEX_DIR" -fasta "$FILES_DIR/kmersFromContigs.fa" -toquery median -withabsent -outpath "$FILES_DIR/KmersFromContigsQuery"
# Phasing prediction
python3 "$SCRIPTS_DIR/add_id_sum.py" "$FILES_DIR/kmersFromContigs.fa" "$FILES_DIR/KmersFromContigsQuery" "$FILES_DIR/KmersFromContigsQuerySum"
python3 "$SCRIPTS_DIR/phaseCount.py" "$FILES_DIR/KmersFromContigsQuerySum" "$FILES_DIR/KmersFromContigsQuerySumPhase" "$PHASE_SHIFT"
python3 "$SCRIPTS_DIR/add_colContFromFastaFile_arg.py" "$FILES_DIR/RS+.fa" "$FILES_DIR/KmersFromContigsQuerySumPhase" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeq"
# Translation
"$SCRIPTS_DIR/translate_st.sh" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeq" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslated" "$FILES_DIR/temp_fasta" "$FILES_DIR/temp_result"
rm "$FILES_DIR/temp_result"
rm "$FILES_DIR/temp_fasta"
# Binomial test
python3 "$SCRIPTS_DIR/binom_test.py" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslated" > "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslatedPvalue"
python3 "$SCRIPTS_DIR/addRSState.py" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslatedPvalue" "$FILES_DIR/RS-" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslatedPvalueRSState"

# Remove temp files:

# Suppression des fichiers temporaires
rm "$FILES_DIR/out"
rm "$FILES_DIR/KmersFromContigsQuery"
rm "$FILES_DIR/KmersFromContigsQuerySumPhase"
rm "$FILES_DIR/KmersFromContigsQuerySumPhaseSeq"
rm "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslated"
rm "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslatedPvalue"
