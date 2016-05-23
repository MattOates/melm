mELM version 1.4
================

mELM is a tool for masking or assigning Eukaryotic Linear Motifs to protein sequences. Both TSV/GFF3 output or FASTA is possible. 
Essentially the tool is a CLI to the ELM.eu.org online resource with additional tools for dealing with short motif assignment within disordered regions.
ANCHOR can be used to attempt to limit motif assignment to those found in disordered or MoRF regions.

Please make sure to cite the original ELM authors when using mELM results:

       Holger Dinkel, Kim Van Roey, Sushama Michael, Norman E. Davey,
       Robert J. Weatheritt, Diana Born, Tobias Speck, Daniel Krueger,
       Gleb Grebnev, Marta KubaX, Marta Strumillo, Bora Uyar,
       Aidan Budd, Brigitte Altenberg, Markus Seiler, Lucia B. Chemes,
       Juliana Glavina, Ignacio E. Sanchez, Francesca Diella,
       and Toby J. Gibson (2014)
       The eukaryotic linear motif resource ELM: 10 years and counting
       Nucl. Acids Res. 42(D1): D259-D266
       doi:10.1093/nar/gkt1047

If you have used mELM with ANCHOR predictions please cite the following:

       Balint Meszaros, Istvan Simon and Zsuzsanna Dosztanyi (2009)
       Prediction of Protein Binding Regions in Disordered Proteins
       PLoS Comput Biol 5(5): e1000376.
       doi:10.1371/journal.pcbi.1000376



Usage
=====

        melm [h,v,u,U,c,i,a,G,E,X,m,n,C,P,l,t,M,D,d] <SEQ FILES...>
           -h, --help
               this message
           -v, --verbose
               receive information about what melm is doing
           -u, --update
               download and start using the latest class definitions from ELM.eu.org
           -U, --upgrade
               upgrade mELM to the latest version from GitHub.com/MattOates/melm
           -c, --list-classes
               get TSV output for the current ELM classes library melm is using
           -i, --list-instances
               get TSV output of all the ELM instances held in the melm cache
           -a, --assign
               do not mask sequences, instead output a TSV format of all the ELM assignments made per sequence
           -G, -GFF3
               produce GFF3 output when using --assign, useful if you wish to add this assignment to a genome browser or similar
           -E <>, --max-class-expect=<>
               filter out ELM classes based on their annotated expectation, bigger E means allow for more common motifs
           -X, --hard-mask
               when masking use replacement 'x' characters instead of just making lower case (soft masking)
           -m, --mask-motifs
               instead of masking sequence free of motifs mask the motif rich regions
           -n <>, --num-elms=<>
               threshold number of elms per residue assigned to mask on
           -C <>, --min-elm-complexity=<>
               set a minimum limit of complexity rate to assign an ELM, larger number means more complex motifs included
           -P <>, --max-elm-probability=<>
               set the maximum ELM probability, if a short motif is found with high probability its perhaps too common to be a true positive
           -l, --logic-filter
               turn on ELM instance-logic filtering, if there are known false positive ELMs of this class matching the assigned sequence exclude from results
           -t <>, --type=<>
               only include ELM classes of a given type: CLV (cleavage sites), DEG (degradation sites), DOC (docking sites), LIG (ligand binding sites), MOD (ptm sites), TRG (targeting sites)
           -M, --morf-filter
               if ANCHOR is installed use that to filter ELM output based on those having shared coverage with a predicted MoRF region
           -D, --disorder-filter
               if ANCHOR is installed use that to filter ELM output based on ANCHOR's IUPred disorder prediction, only include ELMs that fall within disordered regions
           -d <>, --anchor-datapath=<>
               provide the location of the anchor data path, mELM will otherwise assume it's in the same directory as your anchor binary

Example Use Cases
=================

Soft mask regions of a protein that do not contain any plausible ELM motifs

           melm human_proteins.fa > human_proteins_motifs.fa

Soft mask all regions of a protein that contain less than two linear motif classes, accounting for known false positives

           melm --num-motifs=2 --logic-filter human_proteins.fa > human_proteins_motif_rich.fa

Mask all PTM sites with 'X' in a set of seqences

           melm --hard-mask --mask-motifs --type=MOD human_proteins.fa > human_no_ptms.fa

Get a GFF3 file for a whole genomes worth of protein annotations

           melm --assign --GFF3 human_proteins.fa > human_motifs.gff3

Get the latest ELM classes library for use in another script or by yourself

           melm --update --list-classes

Get the latest ELM instances library for use in another script or by yourself

           melm --update --list-instances

License
=======

           melm - Mask and assign ELM motifs in protein sequence libraries
           (C) 2014-2016  Dr Matt E. Oates

           This program is free software: you can redistribute it and/or modify
           it under the terms of the GNU Affero General Public License as
           published by the Free Software Foundation, either version 3 of the
           License, or (at your option) any later version.

           This program is distributed in the hope that it will be useful,
           but WITHOUT ANY WARRANTY; without even the implied warranty of
           MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
           GNU Affero General Public License for more details.

           You should have received a copy of the GNU Affero General Public License
           along with this program.  If not, see <http://www.gnu.org/licenses/>.

