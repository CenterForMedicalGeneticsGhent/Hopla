<template>
<span>
    <ParseSectionImportantTitle />
</span>
</template>


<script>
import Vue from "vue";

import ParseSectionImportantTitle from "./ParseSectionImportantTitle.vue";

export default Vue.extend({    
    props:{
        config: Object,
    },
    components:{
        ParseSectionImportantTitle,
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
