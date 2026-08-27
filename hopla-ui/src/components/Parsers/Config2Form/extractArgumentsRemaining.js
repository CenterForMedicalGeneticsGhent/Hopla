import paramValue from "./paramValue";

export default function extractArgumentsRemaining(paramsObject, config){
    // Retrieve Params
    var limitPmToP= paramValue(paramsObject,"limit.pm.to.P");
    var valueOfP= paramValue(paramsObject,"value.of.P");
    var limitBafToP= paramValue(paramsObject,"limit.baf.to.P");
    var selfContained= paramValue(paramsObject,"self.contained");
    var regionsFlankingSize= paramValue(paramsObject,"regions.flanking.size");
    
    // Assign Params
    if (limitPmToP!==undefined){
        config.configAdvanced.remainingFeatures.limitPmToP = (limitPmToP=="T");
    }
    if (valueOfP!==undefined){
        config.configAdvanced.remainingFeatures.valueOfP = Number(valueOfP);
    }
    if (limitBafToP!==undefined){
        config.configAdvanced.remainingFeatures.limitBafToP= (limitBafToP=="T");
    }
    if (selfContained!==undefined){
        config.configAdvanced.remainingFeatures.selfContained = (selfContained=="T");
    }
    if (regionsFlankingSize!==undefined){
        config.configAdvanced.remainingFeatures.regionsFlankingSize = Number(regionsFlankingSize);
    }

    return config;
}
