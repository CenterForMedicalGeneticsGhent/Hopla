import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";

export default function extractInfoSiblings(paramsObject, config){
    // Retrieve Params
    var sampleIDs=paramsObject.pedigreeMapping.siblings.filter(id => id !== "");
    var indicesOfID=sampleIDs.map(function(d){
        return determinePositionSampleID(d,paramsObject["sample.ids"]);
    }); 
    var genders=indicesOfID.map(function(i){
        return paramsObject["genders"][i];
    });
    var keepLimitIDHardDPs=sampleIDs.map(function(d){
        return determinekeepLimitIDHardDP(d,paramsObject["dp.hard.limit.ids"]);
    }); 
    var keepLimitIDHardAFs=sampleIDs.map(function(d){
        return determinekeepLimitIDHardAF(d,paramsObject["af.hard.limit.ids"]);
    });
    var keepLimitIDSoftDPs=sampleIDs.map(function(d){
        return "hide";
    }); 
    var keepInformativeIDs=sampleIDs.map(function(d){
        return "hide";
    }); 
    var diseaseStati=sampleIDs.map(function(d){
        return determineDiseaseStatus(d,paramsObject["carrier.ids"],paramsObject["affected.ids"],paramsObject["nonaffected.ids"]);
    });


    // Assign Params
    for (let i=0; i<sampleIDs.length;i++){
        config.configPedigree.configSiblings.push({})
        config.configPedigree.configSiblings[i].sampleID=sampleIDs[i];
        config.configPedigree.configSiblings[i].gender=genders[i];
        config.configPedigree.configSiblings[i].keepLimitIDHardDP=keepLimitIDHardDPs[i];
        config.configPedigree.configSiblings[i].keepLimitIDHardAF=keepLimitIDHardAFs[i];
        config.configPedigree.configSiblings[i].keepLimitIDSoftDP=keepLimitIDSoftDPs[i];
        config.configPedigree.configSiblings[i].keepInformativeIDs=keepInformativeIDs[i];
        config.configPedigree.configSiblings[i].diseaseStatus=diseaseStati[i];
    }

    return config;

}