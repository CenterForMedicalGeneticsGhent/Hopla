<template>
<span>
    fam.id={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        familyID: String,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        content: function(){
            return `${this.familyID}`;
        }
    },
    methods:{
    },
})
</script>
