<template>
<span>
    <ParseSectionBAlleleFrequencyProfilesTitle />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionBAlleleFrequencyProfilesTitle from "./ParseSectionBAlleleFrequencyProfilesTitle.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionBAlleleFrequencyProfilesTitle,
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
