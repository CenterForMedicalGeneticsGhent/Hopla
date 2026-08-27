<template>
<v-container>
<v-card>
  <v-card-title>
      Remaining Features
  </v-card-title>
  <v-card-text>
    <InputLimitPmToP v-model="config.limitPmToP" />
    <InputValueOfP :disabled="!config.limitPmToP" v-model="config.valueOfP" />
    <InputRegionsFlankingSize v-model="config.regionsFlankingSize" />
    
  </v-card-text>
</v-card>
</v-container>
</template>


<script>

import InputLimitPmToP from "../Inputs/InputLimitPmToP.vue";
import InputValueOfP from "../Inputs/InputValueOfP.vue";
import InputRegionsFlankingSize from "../Inputs/InputRegionsFlankingSize.vue";

export default {
    name: 'InputArgumentsRemainingFeatures',
    emits: ['update:modelValue'],
    props:{
        modelValue: Object,
    },
    components:{
      InputLimitPmToP,
      InputValueOfP,
      InputRegionsFlankingSize,
    },
    data: function(){
        return{
        }
    },
    computed:{
      config:{
        get: function(){
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
        }
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