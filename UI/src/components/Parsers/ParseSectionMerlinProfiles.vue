<template>
<span>
    <ParseSectionMerlinProfilesTitle />
    <ParseWindowSizeVoting :windowSizeVoting="config.configParameters.merlinProfiles.windowSizeVoting" />
    <ParseKeepChromosomesOnly :keepChromosomesOnly="config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepChromosomesOnly" />
    <ParseKeepRegionsOnly :keepRegionsOnly="config.configParameters.merlinProfiles.keepChromosomesRegionsOnly.keepRegionsOnly" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionMerlinProfilesTitle from "../Parsers/ParseSectionMerlinProfilesTitle.vue"
import ParseWindowSizeVoting from "../Parsers/ParseWindowSizeVoting.vue";
import ParseKeepChromosomesOnly from "../Parsers/ParseKeepChromosomesOnly.vue";
import ParseKeepRegionsOnly from "../Parsers/ParseKeepRegionsOnly.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMerlinProfilesTitle,
        ParseWindowSizeVoting,
        ParseKeepChromosomesOnly,
        ParseKeepRegionsOnly,
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
