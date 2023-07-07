# Hopla without visualization in html format

In this R script, visualization is optional and the outputs used for visualization are exported in csv format.

## Input files

1. A (multisample) vcf.gz file 
2. Several parameter arguments,  in form of a settings file and/or command line arguments

## Additional mandatory argument

**`--settings.file [string]`** Path to settings file

## Additional optional argument

**`--run.visualization [boolean, default=F]`** Whether visualization should be executed

## Output

1. csv file (vcfs.csv) generated from vcf objects
2. csv files generated (parsed_flow.csv & parsed_geno.csv) from merlin output
