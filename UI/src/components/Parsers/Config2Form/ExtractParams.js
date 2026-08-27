export default function extractParams(configString){
    if (typeof configString !== "string" || configString.length > 1024 * 1024) {
        throw new Error("Invalid Hopla configuration");
    }

    var paramsObject = readHeader(Object(),configString);

    // Read region
    paramsObject = readRegion(paramsObject,configString);
    paramsObject = readDisease(paramsObject,configString);
    
    var configArrayNested = configString.split('\n')
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
            return (!(
                d.startsWith("#") ||
                d.startsWith("regions=") ||
                d.startsWith("Disease:")
            ));
        })
        .filter(function(d){
            return d.includes("=") || d.includes(":");
        })
        .map(function(d){
            //split lines in key and value
            var separator = d.indexOf("=");
            if (separator === -1) {
                separator = d.indexOf(":");
            }
            return [d.slice(0, separator), d.slice(separator + 1)];
        })
        .map(function(d){
            //split values by ','
            return [d[0],d[1].split(',')];
        })
        ; 
    
    for (let i=0;i<configArrayNested.length;i++){
        let key=configArrayNested[i][0];
        let value=configArrayNested[i][1];
        paramsObject[key]=value;
    }

    return paramsObject;
}

function findValue(configString,paramToFind){
    var line = configString.split("\n")
        .map(function(d){ return d.trim(); })
        .find(function(d){ return d.startsWith(paramToFind); });
    if (line === undefined) {
        throw new Error("Missing required configuration field: " + paramToFind);
    }
    return line.slice(paramToFind.length);
}

function readHeader(configObject, configString){
    configObject.pedigreeMapping = Object();
    configObject.pedigreeMapping.paternalGrandfather = findValue(configString,"# paternalGrandfather=");
    configObject.pedigreeMapping.paternalGrandmother = findValue(configString,"# paternalGrandmother=");
    configObject.pedigreeMapping.maternalGrandfather = findValue(configString,"# maternalGrandfather=");
    configObject.pedigreeMapping.maternalGrandmother = findValue(configString,"# maternalGrandmother=");
    configObject.pedigreeMapping.father = findValue(configString,"# father=");
    configObject.pedigreeMapping.mother = findValue(configString,"# mother=");
    configObject.pedigreeMapping.siblings = findValue(configString,"# siblings=").split(',');
    configObject.pedigreeMapping.embryos = findValue(configString,"# embryos=").split(',');    
    return configObject;
}

function readRegion(configObject, configString){
    configObject.regions=findValue(configString,"regions=");
    return configObject;
}

function readDisease(configObject, configString){
    configObject.Disease=findValue(configString,"Disease:");
    return configObject;
}

