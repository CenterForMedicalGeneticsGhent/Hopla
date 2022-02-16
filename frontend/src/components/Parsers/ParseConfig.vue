<template>
<div style="font-family: monospace;">
    <ParseSectionMandatory :config="config" />
    <ParseSectionImportant :config="config" />
    <ParseSectionVariantInclusionFilter1 :config="config" />
</div>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatory from "../Parsers/ParseSectionMandatory.vue";
import ParseSectionImportant from "../Parsers/ParseSectionImportant.vue";
import ParseSectionVariantInclusionFilter1 from "../Parsers/ParseSectionVariantInclusionFilter1.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components: {
        ParseSectionMandatory,
        ParseSectionImportant,
        ParseSectionVariantInclusionFilter1,
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
