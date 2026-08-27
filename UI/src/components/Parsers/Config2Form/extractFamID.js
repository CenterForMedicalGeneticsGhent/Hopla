import paramValue from "./paramValue";

export default function extractFamID(paramsObject, config){
    // Retrieve Params
    var famID=paramValue(paramsObject,"fam.id");
    
    // Assign Params
    if (famID!==undefined){
        config.configPedigree.famID=famID;
    }

    return config;
}
