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
        }
    },
    computed:{
      fileVCF: {
        get:function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        },
      },
    },
    methods:{
      //CODE
    },
    mounted:function(){
      //CODE
    },
    watch:{
      //CODE
    },
})
</script>