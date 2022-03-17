export default function extractArgumentsMerlinProfiles(paramsObject, config){
    // Retrieve Params
    var windowSizeVoting = Number(paramsObject["window.size.voting"][0])
    var keepChromosomesOnly = function() {
        if (paramsObject["keep.chromosomes.only"][0]=="T"){
            return true;
        }
        else {
            return false;
        }
    }();
    var keepRegionsOnly = function() {
        if (paramsObject["keep.regions.only"][0]=="T"){
            return true;
        }
        else {
            return false;
        }
    }();

    // Assign Params
    config.configParameters.merlinProfiles.windowSizeVoting = windowSizeVoting;
    config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepChromosomesOnly=keepChromosomesOnly;
    config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepRegionsOnly=keepRegionsOnly;

    return config;
}