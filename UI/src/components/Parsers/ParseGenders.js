export function parseGenders(configPedigree){
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
    //patermalGrandfatjer
    content += function(){
        if (paternalGrandfather.sampleID!='U3'){
            return `${paternalGrandfather.gender},`;
        }
        return "";
    }();
    // paternalGrandmother
    content+=function(){
        if (paternalGrandmother.sampleID!='U4'){
            return `${paternalGrandmother.gender},`;
        }
        return "";
    }();
    // maternalGrandfather
    content+=function(){
        if (maternalGrandfather.sampleID!='U5'){
            return `${maternalGrandfather.gender},`;
        }
        return "";
    }();
    // maternalGrandmother
    content+=function(){
        if (maternalGrandmother.sampleID!='U6'){
            return `${maternalGrandmother.gender},`;
        }
        return "";
    }();
    //father
    content+=function(){
        if (paternalGrandmother.sampleID!="U4" || paternalGrandfather.sampleID!="U3" || father.sampleID!='U1'){
            return `${father.gender},`;
        }
        return "";
    }();
    //mother
    content+=function(){
        if (maternalGrandmother.sampleID!="U6" || maternalGrandfather.sampleID!="U5" || mother.sampleID!='U2'){
            return `${mother.gender},`;
        }
        return "";
    }();
    //siblings
    content+=function(){
        var siblingsString = "";
        for (let i=0; i<siblings.length;i++){
            siblingsString+=`${siblings[i].gender},`
        }
        return siblingsString;
    }();
    //Embryos
    content+=function(){
        var embryoString="";
        for (let i=0; i<embryos.length; i++){
            embryoString+=`${embryos[i].gender},`;
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