<template>
<div style="font-family: monospace;">
<ParseSectionMandatory :config="config" />
</div>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatory from "../Parsers/ParseSectionMandatory.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components: {
        ParseSectionMandatory,
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
