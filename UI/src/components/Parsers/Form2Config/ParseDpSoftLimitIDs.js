export default function parseDpSoftLimitIDs(configPedigree){
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
    //paternalGrandfather
    content+=function(){
        return "";
    }();
    //paternalGrandmother
    content+=function(){
        return "";
    }();
    //maternalGrandfather
    content+=function(){
        return "";
    }();
    //maternalGrandmother
    content+=function(){
        return "";
    }();
    //father
    content+=function(){
        return "";
    }();
    //mother
    content+=function(){
        return "";
    }();
    //siblings
    content+=function(){
        var siblingsString = "";
        return siblingsString;
    }();
    //embryos
    content+=function(){
        var embryoString="";
        for (let i=0;i<embryos.length;i++){
            if (embryos[i].keepLimitIDSoftDP===true){
                embryoString+=`${embryos[i].sampleID},`;
            }
        }
        return embryoString;
    }();
    //Return result
    if (content){
        return content.slice(0,-1);
    }
    else {
        return "";
    }
}