<template>
<span>
    <ParseSectionMandatoryTitle />
    <ParseFileVCF :filePath="config.configParameters.fileVCF" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatoryTitle from "../Parsers/ParseSectionMandatoryTitle.vue";
import ParseFileVCF from "./ParseFileVCF.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMandatoryTitle,
        ParseFileVCF,
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
