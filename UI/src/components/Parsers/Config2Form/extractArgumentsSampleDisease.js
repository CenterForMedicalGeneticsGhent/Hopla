export default function extractArgumentsSampleDisease(paramsObject, config){
    const chrRegExp = /([1-9]|1[0-9]|2[0-2]|X|Y)/;
    const chrStartRegExp = /[0-9]+/;
    const chrEndRegExp = /[0-9]+/;
    const regionRegExp = new RegExp(
        `^chr${chrRegExp.source}:${chrStartRegExp.source}-${chrEndRegExp.source}$`
    );   
    
    // Retrieve Params
    var regions=function(){
        var regionsList = paramsObject["regions"];
        var content=[];
        for (let i=0;i<regionsList.length;i++){
            let currentRegionString = regionsList[i];
            if (currentRegionString.match(regionRegExp)){
                content.push({
                    chr: currentRegionString.split(":")[0],
                    chrStart: Number(currentRegionString.split(":")[1].split("-")[0]),
                    chrEnd: Number(currentRegionString.split(":")[1].split("-")[1]),
                });
            }
        }
        return content;
    }();
    var disease=paramsObject["Disease"][0];
    var inheritance=paramsObject["Inheritance"][0];
    var sequencingNote=paramsObject["Sequencing note"][0];

    // Assign Params
    config.configParameters.sampleDisease.regions = regions;
    config.configParameters.sampleDisease.disease = disease;
    config.configParameters.sampleDisease.inheritance = inheritance;
    config.configParameters.sampleDisease.sequencingNote = sequencingNote;
    
    return config;
}