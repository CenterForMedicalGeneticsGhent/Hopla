<template>
<span>
    <ParseSectionImportantTitle />
    <ParseFatherIDs :configPedigree="config.configPedigree" />
    <ParseMotherIDs :configPedigree="config.configPedigree" />
    <ParseGenders :configPedigree="config.configPedigree" />
    <ParseFileCytoband :filePath="config.configParameters.fileCytoband" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionImportantTitle from "./ParseSectionImportantTitle.vue";
import ParseFatherIDs from "../Parsers/ParseFatherIDs.vue";
import ParseMotherIDs from "../Parsers/ParseMotherIDs.vue";
import ParseGenders from "../Parsers/ParseGenders.vue";
import ParseFileCytoband from "../Parsers/ParseFileCytoband.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionImportantTitle,
        ParseFatherIDs,
        ParseMotherIDs,
        ParseGenders,
        ParseFileCytoband,
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
