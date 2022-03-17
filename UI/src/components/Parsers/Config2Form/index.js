import cloneDeep from "lodash/cloneDeep";

import {default as extractParams} from "./ExtractParams";
import extractFamID from "./extractFamID";
import extractInfoPaternalGrandfather from "./extractInfoPaternalGrandfather";
import extractInfoPaternalGrandmother from "./extractInfoPaternalGrandmother";
import extractInfoMaternalGrandfather from "./extractInfoMaternalGrandfather";
import extractInfoMaternalGrandmother from "./extractInfoMaternalGrandmother";
import extractInfoFather from "./extractInfoFather";
import extractInfoMother from "./extractInfoMother";
import extractInfoSiblings from "./extractInfoSiblings";
import extractInfoEmbryos from "./extractInfoEmbryos";
import extractArgumentsMandatory from "./extractArgumentsMandatory";
import extractArgumentsOptional from "./extractArgumentsOptional";
import extractArgumentsVariantExclusion from "./extractArgumentsVariantExclusion";
import extractArgumentsSampleDisease from "./extractArgumentsSampleDisease";
import extractArgumentsMerlinProfiles from "./extractArgumentsMerlinProfiles";
import extractArgumentsRemaining from "./extractArgumentsRemaining";


import {templateConfig} from "../../Templates";



export function config2Form(configText){
    // transform params into object
    let configParams = extractParams(configText);
    
    // start from basic config template
    let config=cloneDeep(templateConfig);

    // update config with info from file
    config=extractFamID(configParams,config);
    config=extractInfoPaternalGrandfather(configParams,config);
    config=extractInfoPaternalGrandmother(configParams,config);
    config=extractInfoMaternalGrandfather(configParams,config);
    config=extractInfoMaternalGrandmother(configParams,config);
    config=extractInfoFather(configParams,config);
    config=extractInfoMother(configParams,config);
    config=extractInfoSiblings(configParams,config);
    config=extractInfoEmbryos(configParams,config);
    config=extractArgumentsMandatory(configParams,config);
    config=extractArgumentsOptional(configParams,config);
    config=extractArgumentsVariantExclusion(configParams,config);
    config=extractArgumentsSampleDisease(configParams,config);
    config=extractArgumentsMerlinProfiles(configParams,config);
    config=extractArgumentsRemaining(configParams,config);
    
    
    return config;
}