<template>
<div>
    <ParseSectionMandatoryTitle />
</div>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatoryTitle from "../Parsers/ParseSectionMandatoryTitle.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionMandatoryTitle,
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
