export default function determineKeepBafIDs(ID,arrayOfSampleIDS){
    var index = arrayOfSampleIDS.indexOf(ID);
    if (index==-1){
        return false;
    }
    else {
        return true;
    }
}