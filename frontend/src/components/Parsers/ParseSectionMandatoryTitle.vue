<template>
<div>
    <span 
    v-for="i in titleContent.length"
    :key="i"
    >
    {{titleContent[i-1]}}<br>
    </span>
</div>
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
                "# OPGELET, DIT MOET EEN FILE ZIJN, GEEN MAP NAAM"
            ],
        }
    },
    computed:{
    },
    methods:{
    },
})
</script>
