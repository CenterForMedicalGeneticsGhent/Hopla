<template>
<span>
    <ParseSectionMandatoryTitle />
    <ParseFileVCF :filePath="config.configParameters.fileVCF" />
    <ParseSampleIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatoryTitle from "../Parsers/ParseSectionMandatoryTitle.vue";
import ParseFileVCF from "./ParseFileVCF.vue";
import ParseSampleIDs from "../Parsers/ParseSampleIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMandatoryTitle,
        ParseFileVCF,
        ParseSampleIDs,
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
