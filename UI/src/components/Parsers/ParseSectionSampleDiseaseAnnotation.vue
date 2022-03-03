<template>
<span>
    <ParseSequencingNote :sequencingNote="config.configParameters.sampleDisease.sequencingNote" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionSampleDiseaseAnnotationTitle from "../Parsers/ParseSectionSampleDiseaseAnnotationTitle.vue";
import ParseRegions from "../Parsers/ParseRegions.vue";
import ParseReferenceIDs from "../Parsers/ParseReferenceIDs.vue";
import ParseCarrierIDs from "./ParseCarrierIDs";
import ParseAffectedIDs from "./ParseAffectedIDs";
import ParseNonAffectedIDs from "./ParseNonAffectedIDs";
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
