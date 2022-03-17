export default function parseDpHardLimitIDs(configPedigree){
     //IDs
     var paternalGrandfather = configPedigree.configGrandParentsPaternal.paternalGrandfather;
     var paternalGrandmother = configPedigree.configGrandParentsPaternal.paternalGrandmother;
     var maternalGrandfather = configPedigree.configGrandParentsMaternal.maternalGrandfather;
     var maternalGrandmother = configPedigree.configGrandParentsMaternal.maternalGrandmother;
     var father = configPedigree.configParents.father;
     var mother = configPedigree.configParents.mother;
     var siblings = configPedigree.configSiblings;
     var embryos = configPedigree.configEmbryos.embryoList;
     //logic for each relative
     var content="";
     // paternalGrandfather
     content += function(){
        if (paternalGrandfather.sampleID!='U3'){
            if (paternalGrandfather.keepLimitIDHardDP){
                return `${paternalGrandfather.sampleID},`;
            }
            else {
                return ``;
            }
        }
        return "";
    }();
    // paternalGrandmother
    content+= function(){
        if (paternalGrandmother.sampleID!='U4'){
            if (paternalGrandmother.keepLimitIDHardDP){
                return `${paternalGrandmother.sampleID},`;
            }
            else {
                return ``;
            }
        }
        return "";
    }();
    //maternalGrandfather
    content+=function(){
        if (maternalGrandfather.sampleID!='U5'){
            if (maternalGrandfather.keepLimitIDHardDP){
                return `${maternalGrandfather.sampleID},`;
            }
            else {
                return ``;
            }
        }
        return "";
    }();
    //maternalGrandmother
    content+=function(){
        if (maternalGrandmother.sampleID!='U6'){
            if (maternalGrandmother.keepLimitIDHardDP){
                return `${maternalGrandmother.sampleID},`;
            }
            else {
                return ``;
            }
        }
        return "";
    }();
    //father
    content+=function(){
        if (paternalGrandmother.sampleID!="U4" || paternalGrandfather.sampleID!="U3" || father.sampleID!='U1'){
            if (father.keepLimitIDHardDP===true){
                return `${father.sampleID},`;
            }
            else {
                return ``;
            }
        }
        return "";
    }();
    //mother
    content+=function(){
        if (maternalGrandmother.sampleID!="U6" || maternalGrandfather.sampleID!="U5" || mother.sampleID!='U2'){
            if (mother.keepLimitIDHardDP===true){
                return `${mother.sampleID},`;
            }
            else {
                return ``;
            }
        }
        return "";
    }();
    //siblings
    content+=function(){
        var siblingsString = "";
        for (let i=0; i<siblings.length;i++){
            if (siblings[i].keepLimitIDHardDP===true){
                siblingsString+=`${siblings[i].sampleID},`;
            }
        }
        return siblingsString;
    }();
    //embryos
    content+=function(){
        // Do nothing for embryos
        var embryoString="";
        return embryoString;
    }();
    if (content){
        return content.slice(0,-1);
    }
    else {
        return "";
    }
}