export default function parseBafIDs(configPedigree){
    var embryoIDs = configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID});
    var embryos = configPedigree.configEmbryos.embryoList;
    var content=function(){   
        var embryoString="";
        for (let i=0; i<embryos.length; i++){
            if (embryos[i].keepBafProfile){
                embryoString+=`${embryos[i].sampleID},`;
            }
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