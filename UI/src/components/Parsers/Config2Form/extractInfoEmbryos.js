import determinePositionSampleID from "./determinePositionSampleID";
import determinekeepLimitIDHardDP from "./determineKeepLimitIDHardDP";
import determinekeepLimitIDHardAF from "./determineKeepLimitIDHardAF";
import determinekeepLimitIDSoftDP from "./determineKeepLimitIDSoftDP";
import determineKeepInformativeIDs from "./determineKeepInformativeIDs";
import determineDiseaseStatus from "./determineDiseaseStatus";
import determineKeepHeteroIDs from "./determineKeepHeteroIDs";

export default function extractInfoEmbryos(paramsObject, config){
    
    // Retrieve Params
    var sampleIDs=paramsObject.pedigreeMapping.embryos;
    if (!sampleIDs[0]==""){ //check whether there are embryos
        var indicesOfID=sampleIDs.map(function(d){
            return determinePositionSampleID(d,paramsObject["sample.ids"]);
        }); 
        var genders=indicesOfID.map(function(i){
            return paramsObject["genders"][i];
        });
        var keepLimitIDHardDPs=sampleIDs.map(function(d){
            return "hide";
        }); 
        var keepLimitIDHardAFs=sampleIDs.map(function(d){
            return "hide";
        });
        var keepLimitIDSoftDPs=sampleIDs.map(function(d){
            return determinekeepLimitIDSoftDP(d,paramsObject["dp.soft.limit.ids"]);
        }); 
        var keepInformativeIDs=sampleIDs.map(function(d){
            return "hide";
        });
        var keepHeteroIDs=determineKeepHeteroIDs(paramsObject["keep.hetero.ids"]);
        var diseaseStati=sampleIDs.map(function(d){
            return determineDiseaseStatus(d,paramsObject["carrier.ids"],paramsObject["affected.ids"],paramsObject["nonaffected.ids"]);
        });

        // Assign Params
        for (let i=0; i<sampleIDs.length;i++){
            config.configPedigree.configEmbryos.embryoList.push({})
            config.configPedigree.configEmbryos.embryoList[i].sampleID=sampleIDs[i];
            config.configPedigree.configEmbryos.embryoList[i].gender=genders[i];
            config.configPedigree.configEmbryos.embryoList[i].keepLimitIDHardDP=keepLimitIDHardDPs[i];
            config.configPedigree.configEmbryos.embryoList[i].keepLimitIDHardAF=keepLimitIDHardAFs[i];
            config.configPedigree.configEmbryos.embryoList[i].keepLimitIDSoftDP=keepLimitIDSoftDPs[i];
            config.configPedigree.configEmbryos.embryoList[i].keepInformativeIDs=keepInformativeIDs[i];
            config.configPedigree.configEmbryos.embryoList[i].diseaseStatus=diseaseStati[i];
        }
    }
    
    config.configPedigree.configEmbryos.keepHeteroIDs=keepHeteroIDs;
    return config;
    
}