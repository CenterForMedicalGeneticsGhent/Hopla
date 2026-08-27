import derivePedigreeMapping from "./derivePedigreeMapping";

var headerFields = {
    paternalGrandfather: "# paternalGrandfather=",
    paternalGrandmother: "# paternalGrandmother=",
    maternalGrandfather: "# maternalGrandfather=",
    maternalGrandmother: "# maternalGrandmother=",
    father: "# father=",
    mother: "# mother=",
    siblings: "# siblings=",
    embryos: "# embryos=",
};

// Values that may contain ':' or ',' cannot go through the comma-splitting
// argument reader and are taken from their raw line instead.
var lineFields = {
    "regions": "regions=",
    "Disease": "Disease:",
    "Inheritance": "Inheritance:",
    "Sequencing note": "Sequencing note:",
};

// Sample lists are looked up positionally, so an omitted argument has to read
// like an empty one instead of being absent.
var listFields = [
    "sample.ids",
    "father.ids",
    "mother.ids",
    "genders",
    "dp.hard.limit.ids",
    "af.hard.limit.ids",
    "dp.soft.limit.ids",
    "keep.informative.ids",
    "keep.hetero.ids",
    "carrier.ids",
    "affected.ids",
    "nonaffected.ids",
    "baf.ids",
];

export default function extractParams(configString){
    if (typeof configString !== "string" || configString.length > 1024 * 1024) {
        throw new Error("Invalid Hopla configuration");
    }

    var paramsObject = readArguments(configString);
    Object.keys(lineFields).forEach(function(key){
        paramsObject[key] = readLineValue(configString, lineFields[key]);
    });
    listFields.forEach(function(key){
        if (!Array.isArray(paramsObject[key])){
            paramsObject[key] = [""];
        }
    });
    paramsObject.pedigreeMapping = readPedigreeMapping(configString, paramsObject);

    return paramsObject;
}

function readArguments(configString){
    var paramsObject = Object();
    configString.split("\n")
        .map(function(d){
            //remove leading and trailing spaces
            return d.trim();
        })
        .filter(function(d){
            // remove empty lines
            return (d!="")
        })
        .filter(function(d){
            // remove comments
            return (!d.startsWith("#"))
        })
        .filter(function(d){
            // only keep lines with following pattern
            // param[:=]value
            return (d.includes("=") || d.includes(":"))
        })
        .forEach(function(d){
            //split lines in key and value, then split values by ','
            var separator = d.indexOf("=");
            if (separator === -1){
                separator = d.indexOf(":");
            }
            paramsObject[d.slice(0, separator).trim()] = d.slice(separator + 1).split(',');
        });
    return paramsObject;
}

function readLineValue(configString, paramToFind){
    var line = configString.split("\n")
        .map(function(d){ return d.trim(); })
        .find(function(d){ return d.startsWith(paramToFind); });
    if (line === undefined) {
        return undefined;
    }
    return line.slice(paramToFind.length).trim();
}

function readPedigreeMapping(configString, paramsObject){
    var mapping = readHeaderMapping(configString);
    if (mapping !== null){
        return mapping;
    }
    return derivePedigreeMapping(paramsObject);
}

// Configurations exported by the form describe the pedigree explicitly. The
// block is only usable when complete; otherwise the pedigree is derived.
function readHeaderMapping(configString){
    var mapping = Object();
    var relations = Object.keys(headerFields);
    for (let i=0; i<relations.length; i++){
        var value = readLineValue(configString, headerFields[relations[i]]);
        if (value === undefined){
            return null;
        }
        mapping[relations[i]] = value;
    }
    mapping.siblings = mapping.siblings.split(',');
    mapping.embryos = mapping.embryos.split(',');
    return mapping;
}
