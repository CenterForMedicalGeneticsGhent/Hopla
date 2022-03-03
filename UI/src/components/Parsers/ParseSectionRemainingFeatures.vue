<template>
<span>
    <ParseSelfContained :selfContained="config.configAdvanced.remainingFeatures.selfContained" />
    <ParseRegionsFlankingSize :RegionsFlankingSize="config.configAdvanced.remainingFeatures.regionsFlankingSize" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionRemainingFeaturesTitle from "../Parsers/ParseSectionRemainingFeaturesTitle.vue";
import ParseFamilyID from "../Parsers/ParseFamilyID.vue";
import ParseLimitBafToP from "./ParseLimitPmToP.vue";
import ParseLimitPmToP from "../Parsers/ParseLimitPmToP.vue";
import ParseValueOfP from "../Parsers/ParseValueOfP.vue";
import ParseSelfContained from "../Parsers/ParseSelfContained.vue";
import ParseRegionsFlankingSize from "../Parsers/ParseRegionsFlankingSize.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionRemainingFeaturesTitle,
        ParseFamilyID,
        ParseLimitBafToP,
        ParseLimitPmToP,
        ParseValueOfP,
        ParseSelfContained,
        ParseRegionsFlankingSize,
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
