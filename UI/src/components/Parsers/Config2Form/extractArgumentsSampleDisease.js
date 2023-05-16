export default function extractArgumentsSampleDisease(paramsObject, config){
    // Retrieve Params
    var regions=function(){
        var regionString = paramsObject["regions"];
        var content={};
        if (regionString.length > 0){
            content={
                chr: regionString.split(":")[0],
                chrStart: Number(regionString.split(":")[1].split("-")[0]),
                chrEnd: Number(regionString.split(":")[1].split("-")[1]),
            };
        }
        return [content];
    }();
    var disease=paramsObject["Disease"];
    var inheritance=paramsObject["Inheritance"][0];
    var sequencingNote=paramsObject["Sequencing note"][0];

    // Assign Params
    config.configParameters.sampleDisease.regions = regions;
    config.configParameters.sampleDisease.disease = disease;
    config.configParameters.sampleDisease.inheritance = inheritance;
    config.configParameters.sampleDisease.sequencingNote = sequencingNote;

    return config;
}