<template>
<span>
    limit.pm.to.P={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        limitPmToP: Boolean,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            if (this.limitPmToP===true){
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
