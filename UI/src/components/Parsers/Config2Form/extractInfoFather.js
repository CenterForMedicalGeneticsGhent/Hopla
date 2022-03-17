import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";

export default function extractInfoFather(paramsObject, config){
    // Retrieve Params
    var sampleID=paramsObject.pedigreeMapping.father;
    var indexOfID=determinePositionSampleID(sampleID,paramsObject["sample.ids"]);
    var gender=paramsObject["genders"][indexOfID];
    var keepLimitIDHardDP = determinekeepLimitIDHardDP(sampleID,paramsObject["dp.hard.limit.ids"]);
    var keepLimitIDHardAF = determinekeepLimitIDHardAF(sampleID,paramsObject["af.hard.limit.ids"]);
    //var keepLimitIDSoftDP = determinekeepLimitIDSoftDP(sampleID,paramsObject["dp.soft.limit.ids"]);
    var keepLimitIDSoftDP = "hide";
    var keepInformativeIDs = determineKeepInformativeIDs(sampleID,paramsObject["keep.informative.ids"]);
    var diseaseStatus = determineDiseaseStatus(sampleID,paramsObject["carrier.ids"],paramsObject["affected.ids"],paramsObject["nonaffected.ids"]);
    
    // Assign Params
    config.configPedigree.configParents.father.sampleID=sampleID;
    config.configPedigree.configParents.father.gender=gender;
    config.configPedigree.configParents.father.keepLimitIDHardDP=keepLimitIDHardDP;
    config.configPedigree.configParents.father.keepLimitIDHardAF=keepLimitIDHardAF;
    config.configPedigree.configParents.father.keepLimitIDSoftDP=keepLimitIDSoftDP;
    config.configPedigree.configParents.father.keepInformativeIDs=keepInformativeIDs;
    config.configPedigree.configParents.father.diseaseStatus=diseaseStatus;
    return config;
}