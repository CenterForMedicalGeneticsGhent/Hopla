import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";

export default function extractInfoMother(paramsObject, config){
    // Retrieve Params
    var sampleID=paramsObject.pedigreeMapping.mother;
    var indexOfID=determinePositionSampleID(sampleID,paramsObject["sample.ids"]);
    var gender=paramsObject["genders"][indexOfID];
    var keepLimitIDHardDP = determinekeepLimitIDHardDP(sampleID,paramsObject["dp.hard.limit.ids"]);
    var keepLimitIDHardAF = determinekeepLimitIDHardAF(sampleID,paramsObject["af.hard.limit.ids"]);
    //var keepLimitIDSoftDP = determinekeepLimitIDSoftDP(sampleID,paramsObject["dp.soft.limit.ids"]);
    var keepLimitIDSoftDP = "hide";
    var keepBafIDs = "hide";
    var keepInformativeIDs = determineKeepInformativeIDs(sampleID,paramsObject["keep.informative.ids"]);
    var diseaseStatus = determineDiseaseStatus(sampleID,paramsObject["carrier.ids"],paramsObject["affected.ids"],paramsObject["nonaffected.ids"]);
    
    // Assign Params
    config.configPedigree.configParents.mother.sampleID=sampleID;
    config.configPedigree.configParents.mother.gender=gender;
    config.configPedigree.configParents.mother.keepLimitIDHardDP=keepLimitIDHardDP;
    config.configPedigree.configParents.mother.keepLimitIDHardAF=keepLimitIDHardAF;
    config.configPedigree.configParents.mother.keepLimitIDSoftDP=keepLimitIDSoftDP;
    config.configPedigree.configParents.mother.keepBafIDs=keepBafIDs;
    config.configPedigree.configParents.mother.keepInformativeIDs=keepInformativeIDs;
    config.configPedigree.configParents.mother.diseaseStatus=diseaseStatus;
    return config;
}