export function parseBafIDs(configPedigree){
    var embryoIDs = configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID});
    var content=function(){   
        var embryoString="";
        for (let i=0; i<embryoIDs.length; i++){
            embryoString+=`${embryoIDs[i]},`;
        }
        return embryoString;
    }();

    if (content){
        return content.slice(0,-1);
    }
    else {
        return "";
    }
}