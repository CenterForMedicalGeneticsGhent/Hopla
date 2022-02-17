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
            var fatherID = this.configPedigree.configParents.father.sampleID;
            if (this.paternalGrandmother || this.paternalGrandfather || fatherID!='U1'){
                return `${fatherID},`;
            }
            return "";
        },
        mother: function(){
            var motherID = this.configPedigree.configParents.mother.sampleID;
            if (this.maternalGrandmother || this.maternalGrandfather || motherID!='U2'){
                return `${motherID},`;
            }
            return "";
        },
        siblings: function(){
            var siblingIDs = this.configPedigree.configSiblings.map(function(d){return d.sampleID});
            var siblingsString = "";
            for (let i=0; i<siblingIDs.length;i++){
                siblingsString+=`${siblingIDs[i]},`
            }
            return siblingsString;
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
