<template>
<v-container>
<v-card>
    <v-card-title>
        Mandatory Arguments
    </v-card-title>
    <v-card-text>
        <InputFileVCF 
        v-model="fileVCF"
        />
    </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';
import InputFileVCF from "./InputFileVCF.vue";

export default Vue.extend({
    name: 'InputArgumentsMandatory',
    props:{
        value: String,
    },
    components:{
        InputFileVCF,
    },
    data: function(){
        return{
            fileVCF: this.value,
        }
    },
    computed:{
        configWatcher: {
            get: function(){
            return `
                ${JSON.stringify(this.fileVCF)}
            `;
            }
        },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.fileVCF);
      },
    },
    mounted:function(){
        //CODE
    },
    watch:{
      configWatcher:{
        handler: function(newVal,oldVal){
          if (oldVal != newVal){
            this.handleInput();
          }
        },
        deep:false,
        immediate:false,
      },
    },
})
</script>