export function parseFatherIDs(configPedigree){
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
    var paternalGrandfather = function(){
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
    var maternalGrandmother = function(){
        if (maternalGrandmotherID!='U6'){
            return `NA,`;
        }
        return "";
    }();
    var father= function(){  
        if (paternalGrandfatherID!='U3'){
            // If there is paternal grandfather, show its ID
            return `${paternalGrandfatherID},`;
        }
        else if (fatherID=="U1" && paternalGrandfatherID=='U3' && paternalGrandmotherID=='U4'){
            // If father and paternal grandparents are absent, show noting 
            return "";
        }
        return "NA,";
    }();
    var mother = function(){
        if (maternalGrandfatherID!='U5'){
            // If there is maternal grandfather, show its ID
            return `${maternalGrandfatherID},`;
        }
        else if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
            // If mother and maternal grandparents are absent, show noting 
            return "";
        }
        return "NA,";
    }();
    var siblings= function(){
        var siblingsString = "";
        if (fatherID=="U1" && paternalGrandfatherID=='U3' && paternalGrandmotherID=='U4'){
            // If father and paternal grandparents are absent, show NA for each child
            for (let i=0; i<siblingIDs.length;i++){
                siblingsString+=`NA,`;
            }
        }
        else {
            // show ID of father for each child
            for (let i=0; i<siblingIDs.length;i++){
                siblingsString+=`${fatherID},`;
            }
        }
        return siblingsString;
    }();
    var embryos=function(){
        var result = "";
        if (fatherID=="U1" && paternalGrandfatherID=='U3' && paternalGrandmotherID=='U4'){
            // If father and paternal grandparents are absent, show NA for each embryo
            for (let i=0; i<embryoIDs.length;i++){
                result+=`NA,`;
            }
            return result;
        }
        else {
            // show ID of father for each embryo
            for (let i=0; i<embryoIDs.length;i++){
                result+=`${fatherID},`;
            }
            return result;
        }
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