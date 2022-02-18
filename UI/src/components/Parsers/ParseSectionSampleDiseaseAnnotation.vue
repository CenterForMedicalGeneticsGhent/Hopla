<template>
<span>
    <ParseSectionSampleDiseaseAnnotationTitle />
    <ParseRegions :regions="config.configParameters.sampleDisease.regions" />
    <ParseReferenceIDs />
    <ParseCarrierIDs :configPedigree="config.configPedigree" />
    <ParseAffectedIDs :configPedigree="config.configPedigree" />
    <ParseNonAffectedIDs :configPedigree="config.configPedigree" />
    start.info<br>
    <ParseDisease :disease="config.configParameters.sampleDisease.disease" />
    <ParseInheritance :inheritance="config.configParameters.sampleDisease.inheritance" />
    <ParseSequencingNote :sequencingNote="config.configParameters.sampleDisease.sequencingNote" />
    end.info<br>
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionSampleDiseaseAnnotationTitle from "../Parsers/ParseSectionSampleDiseaseAnnotationTitle.vue";
import ParseRegions from "../Parsers/ParseRegions.vue";
import ParseReferenceIDs from "../Parsers/ParseReferenceIDs.vue";
import ParseCarrierIDs from "../Parsers/ParseCarrierIDs.vue";
import ParseAffectedIDs from "../Parsers/ParseAffectedIDs.vue";
import ParseNonAffectedIDs from "../Parsers/ParseNonAffectedIDs.vue";
import ParseDisease from "../Parsers/ParseDisease.vue";
import ParseInheritance from "../Parsers/ParseInheritance.vue";
import ParseSequencingNote from "../Parsers/ParseSequencingNote.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionSampleDiseaseAnnotationTitle,
        ParseRegions,
        ParseReferenceIDs,
        ParseCarrierIDs,
        ParseAffectedIDs,
        ParseNonAffectedIDs,
        ParseDisease,
        ParseInheritance,
        ParseSequencingNote,
    },
    data: function(){
        return {

        }
    },
    computed:{
    },
    methods:{
    },
})
</script>
