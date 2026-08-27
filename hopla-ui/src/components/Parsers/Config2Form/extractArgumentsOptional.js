import paramValue from "./paramValue";

export default function extractArgumentsOptional(paramsObject, config){
    // Retrieve Params
    var fileCytoband=paramValue(paramsObject,"cytoband.file");
    
    // Assign Params
    if (fileCytoband!==undefined){
        config.configParameters.fileCytoband = fileCytoband;
    }

    return config;
}
