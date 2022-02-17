<template>
<span>
    mother.ids={{content}}<br>
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
                return `NA,`;
            }
            return "";
        },
        paternalGrandmother: function(){
            var paternalGrandmotherID = this.configPedigree.configGrandParentsPaternal.paternalGrandmother.sampleID;
            if (paternalGrandmotherID!='U4'){
                return `NA,`;
            }
            return "";
        },
        maternalGrandfather: function(){
            var maternalGrandfatherID = this.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
            if (maternalGrandfatherID!='U5'){
                return `NA,`;
            }
            return "";
        },
        maternalGrandmother: function(){
            var maternalGrandmotherID = this.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
            if (maternalGrandmotherID!='U6'){
                return `NA,`;
            }
            return "";
        },
        father: function(){
            var paternalGrandfatherID = this.configPedigree.configGrandParentsPaternal.paternalGrandfather.sampleID;
            var paternalGrandmotherID = this.configPedigree.configGrandParentsPaternal.paternalGrandmother.sampleID;
            var fatherID = this.configPedigree.configParents.father.sampleID;
            if (paternalGrandmotherID!='U4'){
                // If there is paternal grandmother, show her ID
                return `${paternalGrandmotherID},`;
            }
            else if (fatherID=="U1" && paternalGrandfatherID=='U3' && paternalGrandmotherID=='U4'){
                // If father and paternal grandparents are absent, show noting 
                return "";
            }
            return "NA,";
        },
        mother: function(){
            var maternalGrandfatherID = this.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
            var maternalGrandmotherID = this.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
            var motherID = this.configPedigree.configParents.mother.sampleID;
            if (maternalGrandmotherID!='U6'){
                // If there is maternal grandmother, show her ID
                return `${maternalGrandmotherID},`;
            }
            else if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
                // If mother and maternal grandparents are absent, show noting 
                return "";
            }
            return "NA,";
        },
        siblings: function(){
            var siblingIDs = this.configPedigree.configSiblings.map(function(d){return d.sampleID});
            var maternalGrandfatherID = this.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
            var maternalGrandmotherID = this.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
            var motherID = this.configPedigree.configParents.mother.sampleID;
            var result = "";  
            if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
                // If mother and maternal grandparents are absent, show NA for each sibling
                for (let i=0; i<siblingIDs.length;i++){
                    result+=`NA,`;
                }
            }
            else {
                // show ID of father for each embryo
                for (let i=0; i<siblingIDs.length;i++){
                    result+=`${motherID},`;
                }
            }
            return result;
        },
        embryos: function(){
            var embryoIDs = this.configPedigree.configEmbryos.embryoList.map(function(d){return d.sampleID});
            var maternalGrandfatherID = this.configPedigree.configGrandParentsMaternal.maternalGrandfather.sampleID;
            var maternalGrandmotherID = this.configPedigree.configGrandParentsMaternal.maternalGrandmother.sampleID;
            var motherID = this.configPedigree.configParents.mother.sampleID;
            var result = "";
            if (motherID=="U2" && maternalGrandfatherID=='U5' && maternalGrandmotherID=='U6'){
                // If mother and maternal grandparents are absent, show NA for each embryo
                for (let i=0; i<embryoIDs.length;i++){
                    result+=`NA,`;
                }
            }
            else {
                // show ID of motherr for each embryo
                for (let i=0; i<embryoIDs.length;i++){
                    result+=`${motherID},`;
                }
            }
            return result;

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
