<template>
<span>
    <ParseSectionImportantTitle />
    <ParseFatherIDs :configPedigree="config.configPedigree" />
    <ParseMotherIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionImportantTitle from "./ParseSectionImportantTitle.vue";
import ParseFatherIDs from "../Parsers/ParseFatherIDs.vue";
import ParseMotherIDs from "../Parsers/ParseMotherIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionImportantTitle,
        ParseFatherIDs,
        ParseMotherIDs,
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
