<template>
<span>
    <ParseSectionRemainingFeaturesTitle />
    <ParseFamilyID :familyID="config.configPedigree.famID" />
    <ParseLimitBafToP :limitBafToP="config.configAdvanced.remainingFeatures.limitBafToP" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionRemainingFeaturesTitle from "../Parsers/ParseSectionRemainingFeaturesTitle.vue";
import ParseFamilyID from "../Parsers/ParseFamilyID.vue";
import ParseLimitBafToP from "../Parsers/ParseLimitBafToP.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionRemainingFeaturesTitle,
        ParseFamilyID,
        ParseLimitBafToP,
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
