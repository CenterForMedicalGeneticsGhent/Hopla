<template>
<span>
    <ParseSectionVariantInclusionFilter1Title />
    <ParseDpHardLimitIDs :configPedigree="config.configPedigree" />
    <ParseAfHardLimitIDs :configPedigree="config.configPedigree" />
    <ParseAfHardLimit :afHardLimit="config.configParameters.afHardLimit" />
    <ParseDpSoftLimitIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionVariantInclusionFilter1Title from "../Parsers/ParseSectionVariantInclusionFilter1Title.vue"
import ParseDpHardLimitIDs from "../Parsers/ParseDpHardLimitIDs.vue";
import ParseAfHardLimitIDs from "../Parsers/ParseAfHardLimitIDs.vue";
import ParseAfHardLimit from "./ParseAfHardLimit.vue"
import ParseDpSoftLimitIDs from "../Parsers/ParseDpSoftLimitIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionVariantInclusionFilter1Title,
        ParseDpHardLimitIDs,
        ParseAfHardLimitIDs,
        ParseAfHardLimit,
        ParseDpSoftLimitIDs,
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
