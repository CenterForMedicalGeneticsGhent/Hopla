<template>
<span>
    <ParseSectionRemainingFeaturesTitle />
    <ParseFamilyID :familyID="config.configPedigree.famID" />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionRemainingFeaturesTitle from "../Parsers/ParseSectionRemainingFeaturesTitle.vue";
import ParseFamilyID from "../Parsers/ParseFamilyID.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionRemainingFeaturesTitle,
        ParseFamilyID,
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
