<template>
<span>
    <ParseSectionMerlinProfilesTitle />
    <ParseWindowSizeVoting :windowSizeVoting="config.configParameters.merlinProfiles.windowSizeVoting" />
    <ParseKeepChromosomesOnly :keepChromosomesOnly="config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepChromosomesOnly" />

</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMerlinProfilesTitle from "../Parsers/ParseSectionMerlinProfilesTitle.vue"
import ParseWindowSizeVoting from "../Parsers/ParseWindowSizeVoting.vue";
import ParseKeepChromosomesOnly from "../Parsers/ParseKeepChromosomesOnly.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMerlinProfilesTitle,
        ParseWindowSizeVoting,
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
