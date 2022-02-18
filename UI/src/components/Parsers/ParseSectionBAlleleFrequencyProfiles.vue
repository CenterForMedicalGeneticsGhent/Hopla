<template>
<span>
    <ParseSectionBAlleleFrequencyProfilesTitle />
    <ParseBafIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionBAlleleFrequencyProfilesTitle from "./ParseSectionBAlleleFrequencyProfilesTitle.vue"
import ParseBafIDs from "../Parsers/ParseBafIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionBAlleleFrequencyProfilesTitle,
        ParseBafIDs,
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
