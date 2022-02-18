<template>
<span>
    <ParseSectionVariantInclusionFilter2Title />
    <ParseKeepInformativeIDs :configPedigree="config.configPedigree" />
    <ParseKeepHeteroIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionVariantInclusionFilter2Title from "./ParseSectionVariantInclusionFilter2Title.vue"
import ParseKeepInformativeIDs from "../Parsers/ParseKeepInformativeIDs.vue";
import ParseKeepHeteroIDs from "../Parsers/ParseKeepHeteroIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionVariantInclusionFilter2Title,
        ParseKeepInformativeIDs,
        ParseKeepHeteroIDs,
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
