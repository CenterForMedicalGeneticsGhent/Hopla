<template>
<span>
    <ParseSectionRemainingFeaturesTitle />
    <ParseFamilyID :familyID="config.configPedigree.famID" />
    <ParseLimitBafToP :limitBafToP="config.configAdvanced.remainingFeatures.limitBafToP" />
    <ParseLimitPmToP :limitPmToP="config.configAdvanced.remainingFeatures.limitPmToP" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionRemainingFeaturesTitle from "../Parsers/ParseSectionRemainingFeaturesTitle.vue";
import ParseFamilyID from "../Parsers/ParseFamilyID.vue";
import ParseLimitBafToP from "./ParseLimitPmToP.vue";
import ParseLimitPmToP from "../Parsers/ParseLimitPmToP.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionRemainingFeaturesTitle,
        ParseFamilyID,
        ParseLimitBafToP,
        ParseLimitPmToP,
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
