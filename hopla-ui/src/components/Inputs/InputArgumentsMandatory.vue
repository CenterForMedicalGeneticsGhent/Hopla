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
import InputFileVCF from "./InputFileVCF.vue";

export default {
    name: 'InputArgumentsMandatory',
    emits: ['update:modelValue'],
    props:{
        modelValue: String,
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
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
}
</script>