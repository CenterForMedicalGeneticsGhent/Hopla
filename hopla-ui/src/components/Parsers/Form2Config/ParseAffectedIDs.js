export default function parseAffectedIDs(configPedigree){
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
        if (paternalGrandfather.diseaseStatus=='affected'){
            return `${paternalGrandfather.sampleID},`;
        }
        return "";
    }();
    //paternalGrandmother
    content+=function(){
        if (paternalGrandmother.diseaseStatus=='affected'){
            return `${paternalGrandmother.sampleID},`;
        }
        return "";
    }();
    //maternalGrandfather
    content+=function(){
        if (maternalGrandfather.diseaseStatus=='affected'){
            return `${maternalGrandfather.sampleID},`;
        }
        return "";
    }();
    //maternalGrandmother
    content+=function(){
        if (maternalGrandmother.diseaseStatus=='affected'){
            return `${maternalGrandmother.sampleID},`;
        }
        return "";
    }();
    //father
    content+=function(){
        if (father.diseaseStatus=='affected'){
            return `${father.sampleID},`;
        }
        return "";
    }();
    //mother
    content+=function(){
        if (mother.diseaseStatus=='affected'){
            return `${mother.sampleID},`;
        }
        return "";
    }();
    //siblings
    content+=function(){
        var siblingsString = "";
        for (let i=0; i<siblings.length;i++){
            if (siblings[i].diseaseStatus=="affected"){
                siblingsString+=`${siblings[i].sampleID},`
            }  
        }
        return siblingsString;
    }();
    //embryos: 
    content+=function(){
        var embryoString="";
        for (let i=0; i<embryos.length; i++){
            if (embryos[i].diseaseStatus=="affected"){
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

