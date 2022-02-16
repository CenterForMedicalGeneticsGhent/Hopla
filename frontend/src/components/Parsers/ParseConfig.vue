<template>
<div style="font-family: monospace;">
    <ParseSectionMandatory :config="config" />
    <ParseSectionImportant :config="config" />
    <ParseSectionVariantInclusionFilter1 :config="config" />
    <ParseSectionVariantInclusionFilter2 :config="config" />
    <ParseSectionSampleDiseaseAnnotation :config="config" />
    <ParseSectionBAlleleFrequencyProfiles :config="config" />
    <ParseSectionMerlinProfiles :config="config" />
    <ParseSectionRemainingFeatures :config="config" />
    <br><br><br>
    {{config}}
</div>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatory from "../Parsers/ParseSectionMandatory.vue";
import ParseSectionImportant from "../Parsers/ParseSectionImportant.vue";
import ParseSectionVariantInclusionFilter1 from "../Parsers/ParseSectionVariantInclusionFilter1.vue";
import ParseSectionVariantInclusionFilter2 from "../Parsers/ParseSectionVariantInclusionFilter2.vue";
import ParseSectionSampleDiseaseAnnotation from "../Parsers/ParseSectionSampleDiseaseAnnotation.vue";
import ParseSectionBAlleleFrequencyProfiles from "../Parsers/ParseSectionBAlleleFrequencyProfiles.vue";
import ParseSectionMerlinProfiles from "../Parsers/ParseSectionMerlinProfiles.vue";
import ParseSectionRemainingFeatures from "../Parsers/ParseSectionRemainingFeatures.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components: {
        ParseSectionMandatory,
        ParseSectionImportant,
        ParseSectionVariantInclusionFilter1,
        ParseSectionVariantInclusionFilter2,
        ParseSectionSampleDiseaseAnnotation,
        ParseSectionBAlleleFrequencyProfiles,
        ParseSectionMerlinProfiles,
        ParseSectionRemainingFeatures,
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
