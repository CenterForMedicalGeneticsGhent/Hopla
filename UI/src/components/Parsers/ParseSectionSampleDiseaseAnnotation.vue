<template>
<span>
    <ParseSectionSampleDiseaseAnnotationTitle />
    <ParseRegions :regions="config.configParameters.sampleDisease.regions" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionSampleDiseaseAnnotationTitle from "../Parsers/ParseSectionSampleDiseaseAnnotationTitle.vue";
import ParseRegions from "../Parsers/ParseRegions.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionSampleDiseaseAnnotationTitle,
        ParseRegions,
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
