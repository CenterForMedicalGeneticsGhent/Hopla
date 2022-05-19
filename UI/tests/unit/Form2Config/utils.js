export async function getConfigText(wrapperHoplaForm) {
    await wrapperHoplaForm.find('#tab_config').trigger('click');
    await wrapperHoplaForm.vm.$nextTick();
    return await wrapperHoplaForm.find('#config_text').text();
}

export function removeCommentsFromConfig(configText){
    return configText.replace(/#.*\n/g,'');
}

export const emptyConfigText=`# ------
# HEADER
# ------
# paternalGrandfather=U3
# paternalGrandmother=U4
# maternalGrandfather=U5
# maternalGrandmother=U6
# father=U1
# mother=U2
# siblings=
# embryos=
# -------------------
# MANDATORY ARGUMENTS
# -------------------
vcf.file=/path/to/file.vcf
sample.ids=
# ----------------------------
# IMPORTANT OPTIONAL ARGUMENTS
# ----------------------------
father.ids=
mother.ids=
genders=
cytoband.file=/home/projects/coPGT-M/ref/cytoBand_hg38.txt
# --------------------------------------------------------
# IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 1
# --------------------------------------------------------
dp.hard.limit.ids=
af.hard.limit.ids=
af.hard.limit=0.25
dp.soft.limit.ids=
# --------------------------------------------------------
# IMPORTANT OPTIONAL VARIANT INCLUSION ARGUMENTS: FILTER 2
# --------------------------------------------------------
keep.informative.ids=
keep.hetero.ids=
# -----------------------------------
# OPTIONAL: SAMPLE/DISEASE ANNOTATION
# -----------------------------------
regions=
reference.ids=
carrier.ids=
affected.ids=
nonaffected.ids=
start.info
Disease:
Inheritance:AD
Sequencing note:
end.info
# -------------------------------------
# OPTIONAL: B-ALLELE FREQUENCY PROFILES
# -------------------------------------
baf.ids=
# -------------------------
# OPTIONAL: Merlin Profiles
# -------------------------
window.size.voting=10000000
keep.chromosomes.only=T
keep.regions.only=F
# ----------------------------
# OPTIONAL: REMAINING FEATURES
# ----------------------------
fam.id=famID
limit.baf.to.P=F
limit.pm.to.P=T
value.of.P=0.15
self.contained=T
regions.flanking.size=1000000`;


async function inputSampleID(wrapper, value){
    await wrapper.find('#input_sample_id').setValue(value);
};
async function inputGender(wrapper,value){
    await wrapper.findComponent({name:"InputGender"}).vm.$emit('input',value);
};
async function inputInformativeID(wrapper,boolean){
    await wrapper.find('#input_informative_id').setChecked(boolean);
};
async function inputKeepBafProfile(wrapper,boolean){
    await wrapper.find('#input_baf_profile').setChecked(boolean);
};
async function inputAffected(wrapper,value){
    await wrapper.findComponent({name:"InputAffected"}).vm.$emit('input',value);
};
async function inputDpHardLimitID(wrapper,boolean){
    await wrapper.find('#input_dp_hard_limit_id').setChecked(boolean);
};
async function inputDpSoftLimitID(wrapper,boolean){
    await wrapper.find('#input_dp_soft_limit_id').setChecked(boolean);
};
async function inputAfHardLimitID(wrapper,boolean){
    await wrapper.find('#input_af_hard_limit_id').setChecked(boolean);
};
async function inputKeepHeteroID(wrapper,boolean){
    await wrapper.find('#input_hetero_id').setChecked(boolean);
};

class FatherInputs {
    constructor(params){
        this.sampleID = "defaultFatherID";
        this.gender = "M";
        this.keepInformativeIDs = true;
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addFather(
        wrapper,
        params={},
){
    let Inputs = new FatherInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_father_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let fatherCardElm = await wrapper.find('#input_father_card');

    // fill in fields
    await inputSampleID(fatherCardElm, Inputs.sampleID);
    await inputGender(fatherCardElm, Inputs.gender);
    await inputInformativeID(fatherCardElm,Inputs.keepInformativeIDs);
    await inputAffected(fatherCardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(fatherCardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(fatherCardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class MotherInputs {
    constructor(params){
        this.sampleID = "defaultMotherID";
        this.gender = "F";
        this.keepInformativeIDs = true;
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addMother(
        wrapper,
        params={},
){
    let Inputs = new MotherInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_mother_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let motherCardElm = await wrapper.find('#input_mother_card');

    // fill in fields
    await inputSampleID(motherCardElm, Inputs.sampleID);
    await inputGender(motherCardElm, Inputs.gender);
    await inputInformativeID(motherCardElm,Inputs.keepInformativeIDs);
    await inputAffected(motherCardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(motherCardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(motherCardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class PaternalGrandfatherInputs {
    constructor(params){
        this.sampleID = "defaultPaternalGrandfatherID";
        this.gender = "M";
        this.keepInformativeIDs = false;
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addPaternalGrandfather(
        wrapper,
        params={},
){
    let Inputs = new PaternalGrandfatherInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_paternal_grandfather_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let paternalGrandfatherCardElm = await wrapper.find('#input_paternal_grandfather_card');

    // fill in fields
    await inputSampleID(paternalGrandfatherCardElm, Inputs.sampleID);
    await inputGender(paternalGrandfatherCardElm, Inputs.gender);
    await inputInformativeID(paternalGrandfatherCardElm,Inputs.keepInformativeIDs);
    await inputAffected(paternalGrandfatherCardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(paternalGrandfatherCardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(paternalGrandfatherCardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class PaternalGrandmotherInputs {
    constructor(params){
        this.sampleID = "defaultPaternalGrandmotherID";
        this.gender = "F";
        this.keepInformativeIDs = false;
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addPaternalGrandmother(
        wrapper,
        params={},
){
    let Inputs = new PaternalGrandmotherInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_paternal_grandmother_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let cardElm = await wrapper.find('#input_paternal_grandmother_card');

    // fill in fields
    await inputSampleID(cardElm, Inputs.sampleID);
    await inputGender(cardElm, Inputs.gender);
    await inputInformativeID(cardElm,Inputs.keepInformativeIDs);
    await inputAffected(cardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(cardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(cardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class MaternalGrandfatherInputs {
    constructor(params){
        this.sampleID = "defaultMaternalGrandfatherID";
        this.gender = "M";
        this.keepInformativeIDs = false;
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addMaternalGrandfather(
        wrapper,
        params={},
){
    let Inputs = new MaternalGrandfatherInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_maternal_grandfather_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let cardElm = await wrapper.find('#input_maternal_grandfather_card');

    // fill in fields
    await inputSampleID(cardElm, Inputs.sampleID);
    await inputGender(cardElm, Inputs.gender);
    await inputInformativeID(cardElm,Inputs.keepInformativeIDs);
    await inputAffected(cardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(cardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(cardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class MaternalGrandmotherInputs {
    constructor(params){
        this.sampleID = "defaultMaternalGrandmotherID";
        this.gender = "F";
        this.keepInformativeIDs = false;
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addMaternalGrandmother(
        wrapper,
        params={},
){
    let Inputs = new MaternalGrandmotherInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_maternal_grandmother_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let cardElm = await wrapper.find('#input_maternal_grandmother_card');

    // fill in fields
    await inputSampleID(cardElm, Inputs.sampleID);
    await inputGender(cardElm, Inputs.gender);
    await inputInformativeID(cardElm,Inputs.keepInformativeIDs);
    await inputAffected(cardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(cardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(cardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class SiblingInputs {
    constructor(params){
        this.N = 0;
        this.sampleID = "defaultSiblingID";
        this.gender = "NA";
        this.diseaseStatus =  "NA";
        this.keepLimitIDHardDP =  true;
        this.keepLimitIDHardAF = true;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addSibling(
        wrapper,
        params={},
){
    let Inputs = new SiblingInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_sibling_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let cardElm = await wrapper.findAll('#input_sibling_card').at(Inputs.N);

    // fill in fields
    await inputSampleID(cardElm, Inputs.sampleID);
    await inputGender(cardElm, Inputs.gender);
    await inputAffected(cardElm, Inputs.diseaseStatus);
    await inputDpHardLimitID(cardElm, Inputs.keepLimitIDHardDP);
    await inputAfHardLimitID(cardElm, Inputs.keepLimitIDHardAF);
    
    await wrapper.vm.$nextTick(); 
}

class EmbryoInputs {
    constructor(params){
        this.N = 0;
        this.sampleID = "defaultEmbryoID";
        this.gender = "NA";
        this.diseaseStatus =  "NA";
        this.keepLimitIDSoftDP =  true;
        this.keepBafProfile = true;
        this.keepHetero = false;
        for (let key in params) {
            this[key] = params[key];
        };
    };
}
export async function addEmbryo(
        wrapper,
        params={},
){
    let Inputs = new EmbryoInputs(params);
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    await wrapper.find('#input_embryo_add').trigger('click');
    await wrapper.vm.$nextTick();

    // select father card element
    let cardElm = await wrapper.findAll('#input_embryo_card').at(Inputs.N);

    // fill in fields
    await inputSampleID(cardElm, Inputs.sampleID);
    await inputGender(cardElm, Inputs.gender);
    await inputAffected(cardElm, Inputs.diseaseStatus);
    await inputDpSoftLimitID(cardElm,Inputs.keepLimitIDSoftDP);
    await inputKeepBafProfile(cardElm, Inputs.keepBafProfile);
    await inputKeepHeteroID(wrapper, Inputs.keepHetero);
    
    await wrapper.vm.$nextTick(); 
}