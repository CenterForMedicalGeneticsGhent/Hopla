<template>
<span>
    <ParseSectionMerlinProfilesTitle />
    <ParseDWindowSizeVoting :windowSizeVoting="config.configParameters.merlinProfiles.windowSizeVoting" />
    <ParseKeepChromosomesOnly :keepChromosomesOnly="config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepChromosomesOnly" />

</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMerlinProfilesTitle from "../Parsers/ParseSectionMerlinProfilesTitle.vue"
import ParseDWindowSizeVoting from "../Parsers/ParseDWindowSizeVoting.vue";
import ParseKeepChromosomesOnly from "../Parsers/ParseKeepChromosomesOnly.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMerlinProfilesTitle,
        ParseDWindowSizeVoting,
        ParseKeepChromosomesOnly,
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
