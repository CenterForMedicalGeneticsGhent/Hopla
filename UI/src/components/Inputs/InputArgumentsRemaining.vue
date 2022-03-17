<template>
<v-container>
<v-card>
  <v-card-title>
      Remaining Features
  </v-card-title>
  <v-card-text>
    <InputLimitPmToP v-model="config.limitPmToP" />
    <InputValueOfP :disabled="!config.limitPmToP" v-model="config.valueOfP" />

  </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';

import InputLimitPmToP from "../Inputs/InputLimitPmToP.vue";
import InputValueOfP from "../Inputs/InputValueOfP.vue";

export default Vue.extend({
    name: 'InputArgumentsRemainingFeatures',
    props:{
        value: Object,
    },
    components:{
      InputLimitPmToP,
      InputValueOfP,
    },
    data: function(){
        return{
        }
    },
    computed:{
      config:{
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
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
})
</script>