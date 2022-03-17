<template>
<v-container>
  <v-row
  align="center"
  justify="center"  
  >
    <v-col class="d-flex justify-center align-center">
      <InputArgumentsRemaining v-model="config.remainingFeatures" />
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
      }
    },
    computed:{
      config: {
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
    watch:{
      //CODE
    },  
    })
</script>