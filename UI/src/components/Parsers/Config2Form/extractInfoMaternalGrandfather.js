import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";

export default function extractInfoMaternalGrandfather(paramsObject, config){
    // Retrieve Params
    var sampleID=paramsObject.pedigreeMapping.maternalGrandfather;
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
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID=sampleID;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.gender=gender;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.keepLimitIDHardDP=keepLimitIDHardDP;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.keepLimitIDHardAF=keepLimitIDHardAF;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.keepLimitIDSoftDP=keepLimitIDSoftDP;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.keepBafIDs=keepBafIDs;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.keepInformativeIDs=keepInformativeIDs;
    config.configPedigree.configGrandParentsMaternal.maternalGrandfather.diseaseStatus=diseaseStatus;
    return config;
}