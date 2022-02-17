<template>
<v-container>
<v-card>
  <v-card-title>
      Remaining Features
  </v-card-title>
  <v-card-text>
    <InputLimitPmToP v-model="limitPmToP" />
    <InputValueOfP :disabled="!limitPmToP" v-model="valueOfP" />

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
          limitPmToP: this.value.limitPmToP,
          valueOfP: this.value.valueOfP,
          limitBafToP: this.value.limitBafToP,
          selfContained: this.value.selfContained,
          regionsFlankingSize: this.value.regionsFlankingSize,
        }
    },
    computed:{
      config: {
        get: function(){
          return {
            limitPmToP: this.limitPmToP,
            valueOfP: this.valueOfP,
            limitBafToP: this.limitBafToP,
            selfContained: this.selfContained,
            regionsFlankingSize: this.regionsFlankingSize,
          };
        },
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
      handleInput: function(){
        this.$emit('input',this.config);
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