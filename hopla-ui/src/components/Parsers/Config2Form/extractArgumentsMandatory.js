import paramValue from "./paramValue";

export default function extractArgumentsMandatory(paramsObject, config){
    // Retrieve Params
    var fileVCF=paramValue(paramsObject,"vcf.file");
    
    // Assign Params
    if (fileVCF!==undefined){
        config.configParameters.fileVCF = fileVCF;
    }

    return config;
}
