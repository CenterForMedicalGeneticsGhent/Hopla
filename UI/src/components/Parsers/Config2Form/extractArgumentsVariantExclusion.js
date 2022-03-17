export default function extractArgumentsVariantExclusion(paramsObject, config){
    // Retrieve Params
    var afHardLimit=Number(paramsObject["af.hard.limit"][0]);
    
    // Assign Params
    config.configParameters.afHardLimit = afHardLimit;

    return config;
}