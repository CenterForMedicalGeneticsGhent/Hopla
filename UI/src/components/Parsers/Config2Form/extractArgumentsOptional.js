export default function extractArgumentsOptional(paramsObject, config){
    // Retrieve Params
    var fileCytoband=paramsObject["cytoband.file"][0];
    
    // Assign Params
    config.configParameters.fileCytoband = fileCytoband;

    return config;
}