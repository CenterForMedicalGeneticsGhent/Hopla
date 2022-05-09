// Imports
import cloneDeep from 'lodash/cloneDeep';


// Config Templates
export var templateFather = {
    sampleID: "U1",
    gender: "M",
    keepInformativeIDs: true,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templateMother = {
    sampleID: "U2",
    gender: "F",
    keepInformativeIDs: true,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templatePaternalGrandfather = {
    sampleID: "U3",
    gender: "M",
    keepInformativeIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templatePaternalGrandmother = {
    sampleID: "U4",
    gender: "F",
    keepInformativeIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templateMaternalGrandfather = {
    sampleID: "U5",
    gender: "M",
    keepInformativeIDs: false,
    keepHeteroIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templateMaternalGrandmother = {
    sampleID: "U6",
    gender: "F",
    keepInformativeIDs: false,
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templateSibling = {
    sampleID: "U7",
    gender: "NA",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
    keepBafProfile: "hide",
};
export var templateEmbryo = {
    sampleID: "U8",
    gender: "NA",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: "hide",
    keepLimitIDHardAF: "hide",
    keepLimitIDSoftDP: true,
    keepBafProfile: true,
};
  
export var templatePedigree = {
    famID: "famID",
    configParents: {
        "father": cloneDeep(templateFather),
        "mother": cloneDeep(templateMother),
    },
    configGrandParentsPaternal: {
        "paternalGrandfather": cloneDeep(templatePaternalGrandfather),
        "paternalGrandmother": cloneDeep(templatePaternalGrandmother),
    },
    configGrandParentsMaternal: {
        "maternalGrandfather": cloneDeep(templateMaternalGrandfather),
        "maternalGrandmother": cloneDeep(templateMaternalGrandmother),
    },
    configSiblings: [],
    configEmbryos: {
        embryoList: [],
        keepHeteroIDs: false,
    },
};
export var templateParameters = {
    fileVCF:"/path/to/file.vcf",
    fileCytoband:"/home/projects/coPGT-M/ref/cytoBand_hg38.txt",
    afHardLimit: 0.25,
    sampleDisease:{
        regions:[],
        disease: "",
        inheritance: "AD",
        sequencingNote:"",
    },
    merlinProfiles:{
        windowSizeVoting: 10000000,
        keepChromosomesRegionsOnly:{
            keepChromosomesOnly:true,
            keepRegionsOnly:false,
      }
    }
  };
export var templateAdvanced = {
    remainingFeatures: {
        limitPmToP: true,
        valueOfP: 0.15,
        limitBafToP: false,
        selfContained: true,
        regionsFlankingSize: 1000000,
    },
};
  
export var templateConfig = {
    configPedigree:cloneDeep(templatePedigree),
    configParameters:cloneDeep(templateParameters),
    configAdvanced:cloneDeep(templateAdvanced),
};