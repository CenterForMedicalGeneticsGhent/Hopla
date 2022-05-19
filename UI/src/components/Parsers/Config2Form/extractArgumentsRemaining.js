export default function extractArgumentsRemaining(paramsObject, config){
    // Retrieve Params
    var limitPmToP= function(){
        if (paramsObject["limit.pm.to.P"][0]=="T"){
            return true;
        }
        else {
            return false;
        }
    }();
    var valueOfP= Number(paramsObject["value.of.P"][0]);
    var limitBafToP= false;
    var selfContained= true;
    var regionsFlankingSize= Number(paramsObject["regions.flanking.size"][0]);
    
    // Assign Params
    config.configAdvanced.remainingFeatures.limitPmToP = limitPmToP;
    config.configAdvanced.remainingFeatures.valueOfP = valueOfP;
    config.configAdvanced.remainingFeatures.limitBafToP= limitBafToP;
    config.configAdvanced.remainingFeatures.selfContained = selfContained;
    config.configAdvanced.remainingFeatures.regionsFlankingSize = regionsFlankingSize;


    return config;
}