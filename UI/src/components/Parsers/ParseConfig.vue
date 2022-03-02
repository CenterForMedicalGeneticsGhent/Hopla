<template>
<v-container>
    <pre
    style="font-family: monospace;"
    >
        {{configText}}
    </pre>
    <div 
    :id="idDiv"
    style="font-family: monospace;"
    >
        <!--
        <ParseSectionMandatory :config="config" />

        <ParseSectionImportant :config="config" />
        
        <ParseSectionVariantInclusionFilter1 :config="config" />

        <ParseSectionVariantInclusionFilter2 :config="config" />

        <ParseSectionSampleDiseaseAnnotation :config="config" />
        
        <ParseSectionBAlleleFrequencyProfiles :config="config" />
        
        <ParseSectionMerlinProfiles :config="config" />
        
        <ParseSectionRemainingFeatures :config="config" />
        -->
    </div>
    <br>
    <v-btn
    color="primary"
    dense
    @click="downloadFile()"
    >
      Download
    </v-btn>
</v-container>
</template>


<script>
import Vue from "vue";

import ParseSectionMandatory from "../Parsers/ParseSectionMandatory.vue";
import ParseSectionImportant from "../Parsers/ParseSectionImportant.vue";
import ParseSectionVariantInclusionFilter1 from "../Parsers/ParseSectionVariantInclusionFilter1.vue";
import ParseSectionVariantInclusionFilter2 from "../Parsers/ParseSectionVariantInclusionFilter2.vue";
import ParseSectionSampleDiseaseAnnotation from "../Parsers/ParseSectionSampleDiseaseAnnotation.vue";
import ParseSectionBAlleleFrequencyProfiles from "../Parsers/ParseSectionBAlleleFrequencyProfiles.vue";
import ParseSectionMerlinProfiles from "../Parsers/ParseSectionMerlinProfiles.vue";
import ParseSectionRemainingFeatures from "../Parsers/ParseSectionRemainingFeatures.vue";

export default Vue.extend({    
    props:{
        value: Object,
    },
    components: {
        //ParseSectionMandatory,
        //ParseSectionImportant,
        //ParseSectionVariantInclusionFilter1,
        //ParseSectionVariantInclusionFilter2,
        //ParseSectionSampleDiseaseAnnotation,
        //ParseSectionBAlleleFrequencyProfiles,
        //ParseSectionMerlinProfiles,
        //ParseSectionRemainingFeatures,
    },
    data: function(){
        return {
            config: this.value,
            idDiv: "idConfig"+Math.floor(Math.random()*1000000000),
            configText
        }
    },
    computed:{
        configText: function(){
            return "\n"
                + this.sectionMandatory 
                + this.sectionImportant 
                + this.sectionVariantInclusionFilter1
                + this.sectionVariantInclusionFilter2
                + this.sectionSampleDiseaseAnnotation
                + this.sectionBAlleleFrequencyProfiles
                + this.sectionMerlinProfiles
                + this.sectionRemainingFeatures
                ;
        },

        sectionMandatory: function(){
            return this.sectionMandatoryTitle
                + this.sectionMandatoryVcfFile
                ;
        },
        sectionImportant: function(){
            return "Important section\n";
        },
        sectionVariantInclusionFilter1: function(){
            return "Section VariantInclusionFilter1\n";
        },
        sectionVariantInclusionFilter2: function(){
            return "SectionVariantInclusionFilter2\n";
        },
        sectionSampleDiseaseAnnotation: function(){
            return "sectionSampleDiseaseAnnotation\n";
        },
        sectionBAlleleFrequencyProfiles: function(){
            return "sectionBAlleleFrequencyProfiles\n";
        },
        sectionMerlinProfiles: function(){
            return "sectionMerlinProfiles\n";
        },
        sectionRemainingFeatures: function(){
            return "sectionRemainingFeatures\n";
        },

        fileName: function(){
            return `${this.config.configPedigree.famID}.txt`
        },
        
        sectionMandatoryTitle: function(){
            return "# -------------------\n"
                +  "# MANDATORY ARGUMENTS\n"
                +  "# -------------------\n"
                ;
        },
        sectionMandatoryVcfFile: function(){
            return `vcf.file=${this.config.configParameters.fileVCF}\n`;
        },

        configWatcher: {
            get: function(){
            return `
                ${JSON.stringify(this.config)}
            `;
            }
        },
    },  
    methods:{
        generateConfigText: function(){
            return "\n"
                + this.sectionMandatory 
                + this.sectionImportant 
                + this.sectionVariantInclusionFilter1
                + this.sectionVariantInclusionFilter2
                + this.sectionSampleDiseaseAnnotation
                + this.sectionBAlleleFrequencyProfiles
                + this.sectionMerlinProfiles
                + this.sectionRemainingFeatures
                ;
        },
        handleInput: function(){
            this.$emit('input',this.config);
        },
        downloadFile: function(){
            //html to text
            var text = document.getElementById(this.idDiv)
                .innerHTML
                .replaceAll("<br>","\n")
                .replaceAll("<span>","")
                .replaceAll("</span>","")
                ;
            
            // make blob from text
            var blob = new Blob([text]);

            // create object url
            var url = URL.createObjectURL(blob);
            
            // download file
            var elm = document.createElement("a");
            elm.href=url; //give url to download
            elm.setAttribute("download", this.fileName);//set default download name
            elm.click();
            elm.remove();
        },
    },
    watch:{
        configWatcher:{
            handler: function(newVal,oldVal){
            if (oldVal != newVal){
                this.handleInput();
            }
            },
            deep:false,
            immediate:true,
        },
    },
    mounted: function(){
        //code
    }
})
</script>
