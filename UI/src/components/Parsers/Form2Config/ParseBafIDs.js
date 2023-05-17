export default function parseBafIDs(configPedigree){
    var embryoIDs = configPedigree.configEmbryos.embryoList
        .filter(function(d){return d.keepBafIDs})
        .map(function(d){return d.sampleID});
    var content = embryoIDs.join(",");
    return content || "";
   }