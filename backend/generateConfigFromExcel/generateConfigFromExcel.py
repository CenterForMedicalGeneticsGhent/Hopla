#!/usr/bin/env python

"""
Import libraries
"""
# Base libraries
import argparse

# 3rd party libraries
import pandas as pd


"""
Parse command line arguments
"""
def ArgsParse():
    parser = argparse.ArgumentParser(description='Generate coPGT-M config file from excel')
    parser.add_argument(
        '--excel', 
        help='MANDATORY: Excel file with overview of the different samples and relations between them.',
        required=True,
        type=str,
        )
    parser.add_argument(
        '--output', 
        help='Name of generated config output file (default=coPGT-M_config.txt)',
        default="coPGT-M_config.txt",
        type=str,
        )
    parser.add_argument(
        '--sheetName', 
        help='Name of the sheet where all data is stored in Excel (default=Blad1)',
        default="Blad1",
        type=str,
    )
    parser.add_argument(
        '--cytobandPath', 
        help='Absolute or relative path to the cytoband file (default=/home/projects/coPGT-M/ref/cytoBand_hg38.txt)',
        default="/home/projects/coPGT-M/ref/cytoBand_hg38.txt",
        type=str,
    )
    parser.add_argument(
        '--afHardLimit', 
        help='af.hard.limit parameter (default=0.25)',
        default="0.25",
        type=float,
    )
    parser.add_argument(
        '--referenceIDs',  
        help='default=""',
        default="",
        type=str,
    )
    parser.add_argument(
        '--keepChromosomesOnly',  
        help='Only keep Chromosomes (T/F, default=T)',
        default="T",
        type=str,
    )
    parser.add_argument(
        '--keepRegionsOnly',  
        help='Only keep Regions (T/F, default=F)',
        default="F",
        type=str,
    )
    parser.add_argument(
        '--limitBafToP',  
        help='T/F, (default=F)',
        default="F",
        type=str,
    )
    parser.add_argument(
        '--limitPmToP',  
        help='T/F, (default=T)',
        default="T",
        type=str,
    )
    parser.add_argument(
        '--valueOfP',  
        help='The value of P (default=0.15)',
        default=0.15,
        type=float,
    )
    parser.add_argument(
        '--selfContained',  
        help='T/F, (default=T)',
        default='T',
        type=str,
    )
    return parser.parse_args()


"""
Read excel sheet

takes path ans sheetName as input.
It opens the excel file as dataframe object.
"""
def read_excel(
        path: str,
        sheetName: str, 
):
    return pd.read_excel(
        path,
        sheetName,
        engine='openpyxl',
        keep_default_na=False,
    )


"""
Extract mandatory arguments 
"""
def extractMandatoryArgs(
        df: pd.core.frame.DataFrame,
        outputPath: str,
    ):
    # extract data
    vcfFile = df.columns[0]
    sampleIDs = parseColumn(df,'sample.ids')

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# -------------------\n",
            "# MANDATORY ARGUMENTS\n",
            "# -------------------\n",
            "# OPGELET, DIT MOET EEN FILE ZIJN, GEEN MAP NAAM\n"
            "vcf.file={}\n".format(vcfFile),
            "sample.ids={}\n".format(sampleIDs),
        ],
        )


"""
Extract important optional arguments 
"""
def extractOptionalImportantArgs(
        df: pd.core.frame.DataFrame,
        outputPath: str,
        cytobandPath: str,
    ):
    # extract data
    fatherIDs = parseColumn(df,"father.ids")
    motherIDs = parseColumn(df,"mother.ids")
    genders = parseColumn(df,"genders")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# ----------------------------\n",
            "# IMPORTANT OPTIONAL ARGUMENTS\n",
            "# ----------------------------\n",
            "father.ids={}\n".format(fatherIDs),
            "mother.ids={}\n".format(motherIDs),
            "genders={}\n".format(genders),
            "cytoband.file={}\n".format(cytobandPath),
            ],
        )


"""
Extract IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 1
"""
def extractOptionalVariantInclusionArgsFilter1(
        df: pd.core.frame.DataFrame,
        outputPath: str,
        afHardLimit:float,
    ):
    # extract data
    dpHardLimitIDs=parseColumn(df, "dp.hard.limit.ids")
    afHardLimitIDs=parseColumn(df, "af.hard.limit.ids")
    dpSoftLimitIDs=parseColumn(df, "dp.soft.limit.ids")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# --------------------------------------------------------\n",
            "# IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 1\n",
            "# --------------------------------------------------------\n",
            "dp.hard.limit.ids={}\n".format(dpHardLimitIDs),
            "af.hard.limit.ids={}\n".format(afHardLimitIDs),
            "af.hard.limit={}\n".format(afHardLimit),
            "dp.soft.limit.ids={}\n".format(dpSoftLimitIDs),
            ],
        )


"""
Extract IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 2
"""
def extractOptionalVariantInclusionArgsFilter2(
        df: pd.core.frame.DataFrame,
        outputPath: str,
    ):
    # extract data
    keepInformativeIDs=parseColumn(df, "keep.informative.ids")
    keepHeteroIDs=parseColumn(df, "keep.hetero.ids")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# --------------------------------------------------------\n",
            "# IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 2\n",
            "# --------------------------------------------------------\n",
            "keep.informative.ids={}\n".format(keepInformativeIDs),
            "keep.hetero.id={}\n".format(keepHeteroIDs),
            ],
        )


"""
Extract OPTIONAL SAMPLE / DISEASE ANNOTATION
"""
def extractOptionalSampleDiseaseAnnotation(
        df: pd.core.frame.DataFrame,
        outputPath: str,
        referenceIDs: str,
    ):
    # extract data
    regions=parseColumn(df, "regions")
    carrierIDs=parseColumn(df, "carrier.ids")
    affectedIDs=parseColumn(df, "affected.ids")
    nonaffectedIDs=parseColumn(df, "nonaffected.ids")
    disease=parseColumn(df, "disease")
    inheritance=parseColumn(df, "inheritance")
    sequencingNote=parseColumn(df, "sequencing note")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# -----------------------------------\n",
            "# OPTIONAL: SAMPLE/DISEASE ANNOTATION\n",
            "# -----------------------------------\n",
            "regions={}\n".format(regions),
            "reference.ids={}\n".format(referenceIDs),
            "carrier.ids={}\n".format(carrierIDs),
            "affected.ids={}\n".format(affectedIDs),
            "nonaffected.ids={}\n".format(nonaffectedIDs),
            "start.info\n",
            "Disease:{}\n".format(disease),
            "Inheritance:{}\n".format(inheritance),
            "Sequencing note:{}\n".format(sequencingNote),
            "end.info\n",
            ],
        )


"""
Extract OPTIONAL: B-ALLELE FREQUENCY PROFILES
"""
def extractOptionalBAlleleFrequencyProfiles(
        df: pd.core.frame.DataFrame,
        outputPath: str,
    ):
    # extract data
    bafIDs=parseColumn(df, "baf.ids")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# -------------------------------------\n",
            "# OPTIONAL: B-ALLELE FREQUENCY PROFILES\n",
            "# -------------------------------------\n",
            "baf.ids={}\n".format(bafIDs),
            ],
        )


"""
Extract OPTIONAL: Merlin Profiles
"""
def extractOptionalMerlinProfiles(
        df: pd.core.frame.DataFrame,
        outputPath: str,
        keepChromosomesOnly: str,
        keepRegionsOnly: str,
    ):
    # extract data
    windowSizeVoting=parseColumn(df, "window.size.voting")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# -------------------------\n",
            "# OPTIONAL: Merlin Profiles\n",
            "# -------------------------\n",
            "window.size.voting={}\n".format(windowSizeVoting),
            "keep.chromosomes.only={}\n".format(keepChromosomesOnly),
            "keep.regions.only={}\n".format(keepRegionsOnly),
            ],
        )


"""
Extract OPTIONAL: REMAINING FEATURES
"""
def extractOptionalRemainingfeatures(
        df: pd.core.frame.DataFrame,
        outputPath: str,
        limitBafToP: str,
        limitPmToP: str,
        valueOfP: float,
        selfContained: str,
    ):
    # extract data
    famID=parseColumn(df, "fam.id")
    regionsFlankingSize=parseColumn(df, "regions.flanking.size")

    # Write to config
    writeToOutput(
        outputPath, 
        [
            "# ----------------------------\n",
            "# OPTIONAL: REMAINING FEATURES\n",
            "# ----------------------------\n",
            "# INDIEN\n",
            "fam.id={}\n".format(famID),
            "limit.baf.to.P={}\n".format(limitBafToP),
            "limit.pm.to.P={}\n".format(limitPmToP),
            "value.of.P={}\n".format(valueOfP),
            "self.contained={}\n".format(selfContained),
            "regions.flanking.size={}\n".format(regionsFlankingSize),
            ],
        )


""""
Help functions
"""
def createEmptyOutput(
        outputPath: str,
    ):
    f = open(outputPath,'w')
    f.close()

def writeToOutput(
        outputPath: str,
        linesToWrite: list,
        ignoreWhenStartWith: str = "*",
    ):
    f = open(outputPath,'a')
    f.writelines(linesToWrite)
    f.close()

def parseColumn(
        df: pd.core.frame.DataFrame,
        columnName: str,
        ignoreWhenStartsWith: str="*",
    ):
    listOfValues = [
        str(X)              # make sure values end up as strings (needed for `join`` method)
        for X 
        in df[columnName] 
        if (not str(X).strip().startswith(ignoreWhenStartsWith))    # ignore cells that are comments
        and (len(str(X).strip())>0)                                 # ignore empty cells 
        ] 
    return ','.join(listOfValues)


""""Main"""
def main(
        excelPath: str,
        sheetName: str,
        outputPath: str,
        cytobandPath: str,
        afHardLimit:float,
        referenceIDs: str,
        keepChromosomesOnly: str,
        keepRegionsOnly: str,
        limitBafToP: str,
        limitPmToP: str,
        valueOfP: float,
        selfContained: str,
):
    df = read_excel(excelPath, sheetName)
    createEmptyOutput(outputPath)
    extractMandatoryArgs(df, outputPath)
    extractOptionalImportantArgs(df, outputPath, cytobandPath)
    extractOptionalVariantInclusionArgsFilter1(df, outputPath, afHardLimit)
    extractOptionalVariantInclusionArgsFilter2(df, outputPath)
    extractOptionalSampleDiseaseAnnotation(df, outputPath, referenceIDs)
    extractOptionalBAlleleFrequencyProfiles(df, outputPath)
    extractOptionalMerlinProfiles(df, outputPath, keepChromosomesOnly, keepRegionsOnly)
    extractOptionalRemainingfeatures(df, outputPath, limitBafToP, limitPmToP, valueOfP, selfContained)


"""
When called as command line program
"""
if __name__ == '__main__':
    Args = ArgsParse()
    main(
        Args.excel,
        Args.sheetName,
        Args.output,
        Args.cytobandPath,
        Args.afHardLimit,
        Args.referenceIDs,
        Args.keepChromosomesOnly,
        Args.keepRegionsOnly,
        Args.limitBafToP,
        Args.limitPmToP,
        Args.valueOfP,
        Args.selfContained,
    )
    
        