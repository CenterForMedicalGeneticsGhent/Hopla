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
  
  import InputArgumentsRemaining from "../Inputs/InputArgumentsRemaining.vue";

  export default {
    name: 'TabAdvanced',
    emits: ['update:modelValue'],
    components:{
      InputArgumentsRemaining,
    },
    props:{
      modelValue: Object,
    },
    data: function() {
      return {
      }
    },
    computed:{
      config: {
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
    watch:{
      //CODE
    },  
    }
</script>