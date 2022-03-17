import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";

export default function extractInfoPaternalGrandfather(paramsObject, config){
    // Retrieve Params
    var sampleID=paramsObject.pedigreeMapping.paternalGrandfather;
    var indexOfID=determinePositionSampleID(sampleID,paramsObject["sample.ids"]);
    var gender=paramsObject["genders"][indexOfID];
    var keepLimitIDHardDP = determinekeepLimitIDHardDP(sampleID,paramsObject["dp.hard.limit.ids"]);
    var keepLimitIDHardAF = determinekeepLimitIDHardAF(sampleID,paramsObject["af.hard.limit.ids"]);
    //var keepLimitIDSoftDP = determinekeepLimitIDSoftDP(sampleID,paramsObject["dp.soft.limit.ids"]);
    var keepLimitIDSoftDP = "hide";
    var keepInformativeIDs = determineKeepInformativeIDs(sampleID,paramsObject["keep.informative.ids"]);
    var diseaseStatus = determineDiseaseStatus(sampleID,paramsObject["carrier.ids"],paramsObject["affected.ids"],paramsObject["nonaffected.ids"]);
    
    // Assign Params
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.sampleID=sampleID;
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.gender=gender;
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.keepLimitIDHardDP=keepLimitIDHardDP;
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.keepLimitIDHardAF=keepLimitIDHardAF;
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.keepLimitIDSoftDP=keepLimitIDSoftDP;
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.keepInformativeIDs=keepInformativeIDs;
    config.configPedigree.configGrandParentsPaternal.paternalGrandfather.diseaseStatus=diseaseStatus;
    return config;
}