# Hopla without visualization in html format (Hopla_intern.R)

In this R script, visualization is optional and the outputs used for visualization are exported in csv format.

## Input files

1. A (multisample) vcf.gz file 
2. Several parameter arguments,  in form of a settings file and/or command line arguments

## Additional mandatory argument

**`--settings.file [string]`** Path to settings file

## Additional optional argument

**`--run.visualization [boolean, default=F]`** Whether visualization should be executed

## Output csv files

- **'vcfs.csv'**, Generated from vcf objects
- **'parsed_flow.csv'**, Generated from merlin output
- **'parsed_geno.csv'**, Generated from merlin output
- **'map_list.csv'**, Generated from merlin output
- **'is_corrected.csv'**, Generated from merlin output


# How to read generated output files for further analysis and visualization (R file name)

In this R script, previously generated csv files are read into certain formats of R objects for further analysis and visualization.

## Input files

- **'vcfs.csv'** Generated from vcf objects
- **'parsed_flow.csv'** generated from merlin output
- **'parsed_geno.csv'** generated from merlin output
- **'map_list.csv'** generated from
- **'is_corrected.csv'** generated from merlin output

## Example output

HTML file with 'Haplotyping by Merlin' as an example output.




