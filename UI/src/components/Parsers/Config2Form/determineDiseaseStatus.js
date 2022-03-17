export default function determineDiseaseStatus(ID,arrayOfcarrierIDS,arrayOfAffectedIDS,arrayOfNonaffectedIDS){
    if (arrayOfcarrierIDS.indexOf(ID)!=-1){
        return "carrier";
    }
    else if (arrayOfAffectedIDS.indexOf(ID)!=-1){
        return "affected";
    }
    else if (arrayOfNonaffectedIDS.indexOf(ID)!=-1){
        return "nonaffected";
    }
    else {
        return "NA";
    }
}