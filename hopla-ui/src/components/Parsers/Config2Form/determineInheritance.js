// The form offers the four inheritance codes below, but settings files are
// often written with the spelled-out description instead.
var codes = ["AD","AR","XLD","XLR"];

var descriptions = {
    "autosomal dominant": "AD",
    "autosomal recessive": "AR",
    "x-linked dominant": "XLD",
    "x linked dominant": "XLD",
    "x-linked recessive": "XLR",
    "x linked recessive": "XLR",
};

export default function determineInheritance(value, fallback){
    if (value===undefined){
        return fallback;
    }
    var normalized = String(value).trim();
    if (normalized===""){
        return fallback;
    }
    if (codes.indexOf(normalized.toUpperCase())!==-1){
        return normalized.toUpperCase();
    }
    var description = descriptions[normalized.toLowerCase()];
    if (description!==undefined){
        return description;
    }
    return fallback;
}
