// Settings files written by hand carry no '# HEADER' block, so the pedigree has
// to be reconstructed from the sample.ids/father.ids/mother.ids columns.
// Members the UI models but that are absent from the analysis keep the
// placeholder IDs used by the form templates.
var placeholders = {
    father: "U1",
    mother: "U2",
    paternalGrandfather: "U3",
    paternalGrandmother: "U4",
    maternalGrandfather: "U5",
    maternalGrandmother: "U6",
};

export default function derivePedigreeMapping(paramsObject){
    var sampleIDs = readIDs(paramsObject["sample.ids"]);
    if (sampleIDs.length === 0){
        throw new Error("Missing required configuration field: sample.ids=");
    }
    var fatherIDs = readParentIDs(paramsObject["father.ids"], sampleIDs.length);
    var motherIDs = readParentIDs(paramsObject["mother.ids"], sampleIDs.length);

    var members = sampleIDs.map(function(id, i){
        return { id: id, father: fatherIDs[i], mother: motherIDs[i] };
    });
    var byID = Object();
    members.forEach(function(member){
        byID[member.id] = member;
    });

    var depths = Object();
    members.forEach(function(member){
        depths[member.id] = pedigreeDepth(member.id, byID, Object(), Object());
    });

    var couple = selectYoungestCouple(members, depths);
    var mapping = Object();
    mapping.father = couple.father === null ? placeholders.father : couple.father;
    mapping.mother = couple.mother === null ? placeholders.mother : couple.mother;

    var father = byID[mapping.father];
    mapping.paternalGrandfather = parentOrPlaceholder(father, "father", placeholders.paternalGrandfather);
    mapping.paternalGrandmother = parentOrPlaceholder(father, "mother", placeholders.paternalGrandmother);
    var mother = byID[mapping.mother];
    mapping.maternalGrandfather = parentOrPlaceholder(mother, "father", placeholders.maternalGrandfather);
    mapping.maternalGrandmother = parentOrPlaceholder(mother, "mother", placeholders.maternalGrandmother);

    var embryos = selectEmbryos(couple.children, paramsObject);
    mapping.embryos = embryos;
    mapping.siblings = couple.children.filter(function(id){
        return embryos.indexOf(id) === -1;
    });

    return mapping;
}

function readIDs(rawValue){
    var values = Array.isArray(rawValue) ? rawValue : [];
    return values
        .map(function(d){ return String(d).trim(); })
        .filter(function(d){ return d !== "" && d !== "NA"; });
}

// Parent columns are positional, so 'NA' and missing entries must keep their slot.
function readParentIDs(rawValue, length){
    var values = Array.isArray(rawValue) ? rawValue : [];
    var result = [];
    for (let i=0; i<length; i++){
        var value = values[i] === undefined ? "" : String(values[i]).trim();
        result.push((value === "" || value === "NA") ? null : value);
    }
    return result;
}

function pedigreeDepth(id, byID, resolved, visiting){
    if (resolved[id] !== undefined){
        return resolved[id];
    }
    var member = byID[id];
    if (member === undefined || visiting[id] === true){
        return 0;
    }
    visiting[id] = true;
    var depth = 0;
    if (member.father !== null){
        depth = Math.max(depth, 1 + pedigreeDepth(member.father, byID, resolved, visiting));
    }
    if (member.mother !== null){
        depth = Math.max(depth, 1 + pedigreeDepth(member.mother, byID, resolved, visiting));
    }
    visiting[id] = false;
    resolved[id] = depth;
    return depth;
}

// The form is built around the youngest couple: its children become the
// siblings/embryos and its own parents become the grandparents.
function selectYoungestCouple(members, depths){
    var couples = Object();
    var order = [];
    for (let i=0; i<members.length; i++){
        var member = members[i];
        if (member.father === null && member.mother === null){
            continue;
        }
        var key = String(member.father) + "|" + String(member.mother);
        if (couples[key] === undefined){
            couples[key] = {
                father: member.father,
                mother: member.mother,
                children: [],
                depth: 0,
                lastIndex: -1,
            };
            order.push(key);
        }
        couples[key].children.push(member.id);
        couples[key].depth = Math.max(couples[key].depth, depths[member.id]);
        couples[key].lastIndex = Math.max(couples[key].lastIndex, i);
    }

    var selected = null;
    for (let i=0; i<order.length; i++){
        var candidate = couples[order[i]];
        var deeper = selected === null || candidate.depth > selected.depth;
        var later = selected !== null
            && candidate.depth === selected.depth
            && candidate.lastIndex > selected.lastIndex;
        if (deeper || later){
            selected = candidate;
        }
    }
    if (selected === null){
        throw new Error("Cannot reconstruct the pedigree: no father.ids or mother.ids relationships were found");
    }
    return selected;
}

function parentOrPlaceholder(member, relation, placeholder){
    if (member === undefined || member[relation] === null){
        return placeholder;
    }
    return member[relation];
}

// Hopla applies dp.soft.limit.ids (and reports BAF profiles) to the last line of
// children, which is what the form calls embryos.
function selectEmbryos(children, paramsObject){
    var hints = readIDs(paramsObject["dp.soft.limit.ids"]);
    if (hints.length === 0){
        hints = readIDs(paramsObject["baf.ids"]);
    }
    var embryos = children.filter(function(id){
        return hints.indexOf(id) !== -1;
    });
    if (embryos.length === 0){
        return children.slice();
    }
    return embryos;
}
