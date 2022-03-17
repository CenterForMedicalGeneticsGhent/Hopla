export default function extractArgumentsMandatory(paramsObject, config){
    // Retrieve Params
    var fileVCF=paramsObject["vcf.file"][0];
    
    // Assign Params
    config.configParameters.fileVCF = fileVCF;

    return config;
}