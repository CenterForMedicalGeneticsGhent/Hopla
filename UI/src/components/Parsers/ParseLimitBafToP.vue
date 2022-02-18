<template>
<span>
    limit.baf.to.P={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        limitBafToP: Boolean,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            if (this.limitBafToP===true){
                return 'T';
            }
            else {
                return 'F';
            }
        }
    },
    methods:{
    },
})
</script>
