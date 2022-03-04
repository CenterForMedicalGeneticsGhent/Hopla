export function parseMotherIDs(configPedigree){
    //IDs
    var paternalGrandfatherID = configPedigree.configGrandParentsPaternal.paternalGrandfather.sampleID;
    var paternalGrandmotherID = configPedigree.configGrandParentsPaternal.paternalGrandmother.sampleID;
    var maternalGrandfatherID = configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
    var maternalGrandmotherID = configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
    var fatherID = configPedigree.configParents.father.sampleID;
    var motherID = configPedigree.configParents.mother.sampleID;
    var siblingIDs = configPedigree.configSiblings.map(function(d){return d.sampleID});
    var embryoIDs = configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID});
    //logic for each relative
    var paternalGrandfather= function(){
        if (paternalGrandfatherID!='U3'){
            return `NA,`;
        }
        return "";
    }();
    var paternalGrandmother= function(){
        if (paternalGrandmotherID!='U4'){
            return `NA,`;
        }
        return "";
    }();
    var maternalGrandfather= function(){
        if (maternalGrandfatherID!='U5'){
            return `NA,`;
        }
        return "";
    }();
    var maternalGrandmother= function(){
        if (maternalGrandmotherID!='U6'){
            return `NA,`;
        }
        return "";
    }();
    var father= function(){
        if (paternalGrandmotherID!='U4'){
            // If there is paternal grandmother, show her ID
            return `${paternalGrandmotherID},`;
        }
        else if (fatherID=="U1" && paternalGrandfatherID=='U3' && paternalGrandmotherID=='U4'){
            // If father and paternal grandparents are absent, show noting 
            return "";
        }
        return "NA,";
    }();
    var mother= function(){
        if (maternalGrandmotherID!='U6'){
            // If there is maternal grandmother, show her ID
            return `${maternalGrandmotherID},`;
        }
        else if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
            // If mother and maternal grandparents are absent, show noting 
            return "";
        }
        return "NA,";
    }();
    var siblings= function(){
        var result = "";  
        if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
            // If mother and maternal grandparents are absent, show NA for each sibling
            for (let i=0; i<siblingIDs.length;i++){
                result+=`NA,`;
            }
        }
        else {
            // show ID of father for each embryo
            for (let i=0; i<siblingIDs.length;i++){
                result+=`${motherID},`;
            }
        }
        return result;
    }();
    var embryos= function(){
        var result = "";
        if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
            // If mother and maternal grandparents are absent, show NA for each embryo
            for (let i=0; i<embryoIDs.length;i++){
                result+=`NA,`;
            }
        }
        else {
            // show ID of motherr for each embryo
            for (let i=0; i<embryoIDs.length;i++){
                result+=`${motherID},`;
            }
        }
        return result;

    }();
    // combine together
    var content=    paternalGrandfather
                +   paternalGrandmother
                +   maternalGrandfather
                +   maternalGrandmother
                +   father
                +   mother
                +   siblings
                +   embryos
                ;
    if (content){ //see if empty or not
        return content.slice(0,-1);
    }
    else {
        return "";
    }
}