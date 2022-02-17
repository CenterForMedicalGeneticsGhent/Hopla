<template>
<span>
    <ParseSectionMerlinProfilesTitle />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMerlinProfilesTitle from "../Parsers/ParseSectionMerlinProfilesTitle.vue"

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMerlinProfilesTitle,
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
