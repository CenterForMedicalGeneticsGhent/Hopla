<template>
<span>
    <span 
    v-for="i in titleContent.length"
    :key="i"
    >
    {{titleContent[i-1]}}<br>
    </span>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
    },
    data: function(){
        return {
            titleContent: [
                "# -------------------",
                "# MANDATORY ARGUMENTS",
                "# -------------------",
            ],
        }
    },
    computed:{
    },
    methods:{
    },
})
</script>
