<template>
<span>
    regions.flanking.size={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        RegionsFlankingSize: Number,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.RegionsFlankingSize}`;
        }
    },
    methods:{
    },
})
</script>
