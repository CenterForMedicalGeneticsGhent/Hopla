export default function determineKeepHeteroIDs(arrayOfSampleIDs){
    if (arrayOfSampleIDs[0]!=""){
        return true;
    }
    else {
        return false;
    }
}