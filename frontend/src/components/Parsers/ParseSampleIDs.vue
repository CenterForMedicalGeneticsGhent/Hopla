<template>
<span>
    sample.ids={{content}}<br>
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
            var paternalGrandfatherID = this.configPedigree.configGrandParentsPaternal.paternalGrandfather.sampleID;
            if (paternalGrandfatherID!='U3'){
                return `${paternalGrandfatherID},`;
            }
            return "";
        },
        paternalGrandmother: function(){
            var paternalGrandmotherID = this.configPedigree.configGrandParentsPaternal.paternalGrandmother.sampleID;
            if (paternalGrandmotherID!='U4'){
                return `${paternalGrandmotherID},`;
            }
            return "";
        },
        maternalGrandfather: function(){
            var maternalGrandfatherID = this.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
            if (maternalGrandfatherID!='U5'){
                return `${maternalGrandfatherID},`;
            }
            return "";
        },
        maternalGrandmother: function(){
            var maternalGrandmotherID = this.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
            if (maternalGrandmotherID!='U6'){
                return `${maternalGrandmotherID},`;
            }
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
            return "";
        },
        content: function(){
            return `${this.paternalGrandfather}${this.paternalGrandmother}${this.maternalGrandfather}${this.maternalGrandmother}${this.siblings}${this.embryos}
            `;
        }
    },
    methods:{
    },
})
</script>
