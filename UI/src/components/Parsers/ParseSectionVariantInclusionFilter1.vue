<template>
<span>
    <ParseSectionVariantInclusionFilter1Title />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionVariantInclusionFilter1Title from "../Parsers/ParseSectionVariantInclusionFilter1Title.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionVariantInclusionFilter1Title,
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
