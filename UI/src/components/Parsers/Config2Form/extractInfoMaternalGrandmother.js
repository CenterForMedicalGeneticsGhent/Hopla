import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";

export default function extractInfoMaternalGrandmother(paramsObject, config){
    // Retrieve Params
    var sampleID=paramsObject.pedigreeMapping.maternalGrandmother;
    var indexOfID=determinePositionSampleID(sampleID,paramsObject["sample.ids"]);
    var gender=paramsObject["genders"][indexOfID];
    var keepLimitIDHardDP = determinekeepLimitIDHardDP(sampleID,paramsObject["dp.hard.limit.ids"]);
    var keepLimitIDHardAF = determinekeepLimitIDHardAF(sampleID,paramsObject["af.hard.limit.ids"]);
    //var keepLimitIDSoftDP = determinekeepLimitIDSoftDP(sampleID,paramsObject["dp.soft.limit.ids"]);
    var keepLimitIDSoftDP = "hide";
    var keepInformativeIDs = determineKeepInformativeIDs(sampleID,paramsObject["keep.informative.ids"]);
    var diseaseStatus = determineDiseaseStatus(sampleID,paramsObject["carrier.ids"],paramsObject["affected.ids"],paramsObject["nonaffected.ids"]);
    
    // Assign Params
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID=sampleID;
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.gender=gender;
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.keepLimitIDHardDP=keepLimitIDHardDP;
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.keepLimitIDHardAF=keepLimitIDHardAF;
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.keepLimitIDSoftDP=keepLimitIDSoftDP;
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.keepInformativeIDs=keepInformativeIDs;
    config.configPedigree.configGrandParentsMaternal.maternalGrandmother.diseaseStatus=diseaseStatus;
    return config;
}