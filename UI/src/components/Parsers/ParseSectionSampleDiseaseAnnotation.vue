<template>
<span>
    <ParseSectionSampleDiseaseAnnotationTitle />
    <ParseRegions :regions="config.configParameters.sampleDisease.regions" />
    <ParseReferenceIDs />
    <ParseCarrierIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionSampleDiseaseAnnotationTitle from "../Parsers/ParseSectionSampleDiseaseAnnotationTitle.vue";
import ParseRegions from "../Parsers/ParseRegions.vue";
import ParseReferenceIDs from "../Parsers/ParseReferenceIDs.vue";
import ParseCarrierIDs from "../Parsers/ParseCarrierIDs.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionSampleDiseaseAnnotationTitle,
        ParseRegions,
        ParseReferenceIDs,
        ParseCarrierIDs,
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
