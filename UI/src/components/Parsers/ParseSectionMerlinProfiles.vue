<template>
<span>
    <ParseSectionMerlinProfilesTitle />
    <ParseDWindowSizeVoting :windowSizeVoting="config.configParameters.merlinProfiles.windowSizeVoting" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMerlinProfilesTitle from "../Parsers/ParseSectionMerlinProfilesTitle.vue"
import ParseDWindowSizeVoting from "../Parsers/ParseDWindowSizeVoting.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMerlinProfilesTitle,
        ParseDWindowSizeVoting,
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
