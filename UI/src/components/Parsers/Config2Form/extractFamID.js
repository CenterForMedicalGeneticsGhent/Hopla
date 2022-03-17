export default function extractFamID(paramsObject, config){
    // Retrieve Params
    var famID=paramsObject["fam.id"][0];
    
    // Assign Params
    config.configPedigree.famID=famID;

    return config;
}