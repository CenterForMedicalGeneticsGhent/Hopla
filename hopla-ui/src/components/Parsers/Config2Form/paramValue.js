// Unset or omitted arguments must keep the form default rather than overwrite
// it, so absent and blank values are both reported as undefined.
export default function paramValue(paramsObject, key){
    var raw = paramsObject[key];
    if (Array.isArray(raw)){
        raw = raw[0];
    }
    if (raw === undefined || raw === null){
        return undefined;
    }
    var value = String(raw).trim();
    return value === "" ? undefined : value;
}
