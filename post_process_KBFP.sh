#!/bin/sh
source /home/safa.maddouri/miniconda3/bin/activate 

# Variables
FILES_DIR="/store/EQUIPES/SSFA/MEMBERS/safa.maddouri/kmerBasedFramePedictor/RESULTS"
SCRIPTS_DIR="/store/EQUIPES/SSFA/MEMBERS/safa.maddouri/kmerBasedFramePedictor/SCRIPTS"

# Exécution des scripts de post-traitement
python3 "$SCRIPTS_DIR/plotPhase.py" "$FILES_DIR/KmersFromContigsQuerySumPhaseSeqTranslatedPvalueRSState" "$FILES_DIR/plots"
python3 "$SCRIPTS_DIR/plotdist.py" "$FILES_DIR/KmersFromContigsQuerySum" "$FILES_DIR/plots"
python3 "$SCRIPTS_DIR/merge_cont.py" "$FILES_DIR/plots"
python3 "$SCRIPTS_DIR/plot_dis_phase_histogrames.py" "$FILES_DIR/KmersFromContigsQuerySum" "$FILES_DIR/plots"
find "$FILES_DIR" -type f \( -name "*_plot.png" -o -name "*_phase.png" \) -delete
