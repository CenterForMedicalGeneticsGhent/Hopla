<template>
<v-container>
  <v-row
  align="center"
  justify="center"  
  >
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsRemaining v-model="remainingFeatures" />
    </v-col>
    <v-col class="d-flex justify-center align-center">
    </v-col>
    <v-col class="d-flex justify-center align-center">
    </v-col>
  </v-row>
</v-container>
</template>

<script>
  import Vue from 'vue'
  
  import InputArgumentsRemaining from "../Inputs/InputArgumentsRemaining.vue";

  export default Vue.extend({
    name: 'TabAdvanced',
    components:{
      InputArgumentsRemaining,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        remainingFeatures: this.value.remainingFeatures,
      }
    },
    computed:{
      config: function(){
        return {
          remainingFeatures: this.remainingFeatures,
        };
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
      }
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
    })
</script>