<template>
<span>
    baf.ids={{content}}<br>
</span>
</template>


<script>
import Vue from "vue";

export default Vue.extend({    
    props:{
        configPedigree: Object,
    },
    components: {
    },
    data: function(){
        return {
        }
    },
    computed:{
        paternalGrandfather: function(){
            return "";
        },
        paternalGrandmother: function(){
            return "";
        },
        maternalGrandfather: function(){
            return "";
        },
        maternalGrandmother: function(){
            return "";
        },
        father: function(){
            return "";
        },
        mother: function(){
            return "";
        },
        siblings: function(){
            return "";
        },
        embryos: function(){
            var embryoIDs = this.configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID});
            var embryoString="";
            for (let i=0; i<embryoIDs.length; i++){
                embryoString+=`${embryoIDs[i]},`;
            }
            return embryoString;
        },
        content: function(){
            var content=`${this.paternalGrandfather}${this.paternalGrandmother}${this.maternalGrandfather}${this.maternalGrandmother}${this.father}${this.mother}${this.siblings}${this.embryos}`;
            if (content){
                return content.slice(0,-1);
            }
            else {
                return "";
            }
        }
    },
    methods:{
    },
})
</script>
