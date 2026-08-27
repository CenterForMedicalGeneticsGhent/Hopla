import paramValue from "./paramValue";

export default function extractArgumentsVariantExclusion(paramsObject, config){
    // Retrieve Params
    var afHardLimit=paramValue(paramsObject,"af.hard.limit");
    
    // Assign Params
    if (afHardLimit!==undefined){
        config.configParameters.afHardLimit = Number(afHardLimit);
    }

    return config;
}
