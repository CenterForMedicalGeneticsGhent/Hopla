<template>
<span>
    <ParseSectionRemainingFeaturesTitle />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionRemainingFeaturesTitle from "../Parsers/ParseSectionRemainingFeaturesTitle.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionRemainingFeaturesTitle,
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
