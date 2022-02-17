<template>
<span>
    <ParseSectionVariantInclusionFilter2Title />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionVariantInclusionFilter2Title from "./ParseSectionVariantInclusionFilter2Title.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionVariantInclusionFilter2Title,
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
