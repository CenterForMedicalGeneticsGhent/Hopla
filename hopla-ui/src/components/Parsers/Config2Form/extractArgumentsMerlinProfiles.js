import paramValue from "./paramValue";

export default function extractArgumentsMerlinProfiles(paramsObject, config){
    // Retrieve Params
    var windowSizeVoting = paramValue(paramsObject,"window.size.voting");
    var keepChromosomesOnly = paramValue(paramsObject,"keep.chromosomes.only");
    var keepRegionsOnly = paramValue(paramsObject,"keep.regions.only");

    // Assign Params
    if (windowSizeVoting!==undefined){
        config.configParameters.merlinProfiles.windowSizeVoting = Number(windowSizeVoting);
    }
    if (keepChromosomesOnly!==undefined){
        config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepChromosomesOnly=(keepChromosomesOnly=="T");
    }
    if (keepRegionsOnly!==undefined){
        config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepRegionsOnly=(keepRegionsOnly=="T");
    }

    return config;
}
