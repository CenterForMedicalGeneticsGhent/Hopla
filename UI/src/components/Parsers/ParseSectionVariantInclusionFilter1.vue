<template>
<span>
    <ParseSectionVariantInclusionFilter1Title />
    <ParseDpHardLimitIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionVariantInclusionFilter1Title from "../Parsers/ParseSectionVariantInclusionFilter1Title.vue"
import ParseDpHardLimitIDs from "../Parsers/ParseDpHardLimitIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionVariantInclusionFilter1Title,
        ParseDpHardLimitIDs,
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
