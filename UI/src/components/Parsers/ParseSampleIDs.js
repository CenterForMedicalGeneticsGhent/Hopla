export function parseSampleIDs(configPedigree){
    var paternalGrandfather = function(){
        var paternalGrandfatherID = configPedigree.configGrandParentsPaternal.paternalGrandfather.sampleID;
        if (paternalGrandfatherID!='U3'){
            return `${paternalGrandfatherID},`;
        }
        return "";
    }
    var paternalGrandmother= function(){
        var paternalGrandmotherID = configPedigree.configGrandParentsPaternal.paternalGrandmother.sampleID;
        if (paternalGrandmotherID!='U4'){
            return `${paternalGrandmotherID},`;
        }
        return "";
    }
    var maternalGrandfather= function(){
        var maternalGrandfatherID = configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
        if (maternalGrandfatherID!='U5'){
            return `${maternalGrandfatherID},`;
        }
        return "";
    }
    var maternalGrandmother= function(){
        var maternalGrandmotherID = configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
        if (maternalGrandmotherID!='U6'){
            return `${maternalGrandmotherID},`;
        }
        return "";
    }
    var father= function(){
        var fatherID = configPedigree.configParents.father.sampleID;
        if (paternalGrandmother() || paternalGrandfather() || fatherID!='U1'){
            return `${fatherID},`;
        }
        return "";
    }
    var mother= function(){
        var motherID = configPedigree.configParents.mother.sampleID;
        if (maternalGrandmother() || maternalGrandfather() || motherID!='U2'){
            return `${motherID},`;
        }
        return "";
    }
    var siblings= function(){
        var siblingIDs = configPedigree.configSiblings.map(function(d){return d.sampleID});
        var siblingsString = "";
        for (let i=0; i<siblingIDs.length;i++){
            siblingsString+=`${siblingIDs[i]},`
        }
        return siblingsString;
    }
    var embryos = function(){
        var embryoIDs = configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID});
        var embryoString="";
        for (let i=0; i<embryoIDs.length; i++){
            embryoString+=`${embryoIDs[i]},`;
        }
        return embryoString;
    }
    var content= function(){
        var c=`${paternalGrandfather()}${paternalGrandmother()}${maternalGrandfather()}${maternalGrandmother()}${father()}${mother()}${siblings()}${embryos()}`;
        if (c){
            return c.slice(0,-1);
        }
        else {
            return "";
        }
    }
    return content()
}
