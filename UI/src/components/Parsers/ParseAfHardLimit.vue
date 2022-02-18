<template>
<span>
    af.hard.limit={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        afHardLimit: Number,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.afHardLimit}`;
        }
    },
    methods:{
    },
})
</script>
