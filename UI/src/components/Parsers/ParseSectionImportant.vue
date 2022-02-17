<template>
<span>
    <ParseSectionImportantTitle />
    <ParseFatherIDs :configPedigree="config.configPedigree" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionImportantTitle from "./ParseSectionImportantTitle.vue";
import ParseFatherIDs from "../Parsers/ParseFatherIDs.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionImportantTitle,
        ParseFatherIDs,
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
