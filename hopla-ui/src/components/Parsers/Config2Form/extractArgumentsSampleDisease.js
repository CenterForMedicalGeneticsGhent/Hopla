import determineInheritance from "./determineInheritance";

export default function extractArgumentsSampleDisease(paramsObject, config){
    // Retrieve Params
    var regions=function(){
        var regionString = paramsObject["regions"];
        if (regionString===undefined || regionString.length === 0){
            return undefined;
        }
        var match = regionString.match(/^(.+):(\d+)-(\d+)$/);
        if (match === null){
            return undefined;
        }
        return [{
            chr: match[1],
            chrStart: Number(match[2]),
            chrEnd: Number(match[3]),
        }];
    }();
    var disease=paramsObject["Disease"];
    var inheritance=paramsObject["Inheritance"];
    var sequencingNote=paramsObject["Sequencing note"];

    // Assign Params
    config.configParameters.sampleDisease.regions = regions===undefined ? [] : regions;
    if (disease!==undefined){
        config.configParameters.sampleDisease.disease = disease;
    }
    config.configParameters.sampleDisease.inheritance = determineInheritance(
        inheritance,
        config.configParameters.sampleDisease.inheritance
    );
    if (sequencingNote!==undefined){
        config.configParameters.sampleDisease.sequencingNote = sequencingNote;
    }

    return config;
}
