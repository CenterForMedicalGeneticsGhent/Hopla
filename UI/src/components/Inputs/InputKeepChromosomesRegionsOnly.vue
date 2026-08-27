<template>
    <v-radio-group
    class="ma-0 pa-0"
    v-model="config"
    density="compact"
    >
      <v-radio
        label="Show everything"
        :value="0"
      ></v-radio>
      <v-radio
        label="Only show chromosome of interest"
        :value="1"
      ></v-radio>
      <v-radio
        label="Only show region of interest"
        :value="2"
      ></v-radio>
    </v-radio-group>
</template>


<script>


export default {
    name:"InputKeepChromosomesRegionsOnly",
    emits: ['update:modelValue'],
    props:{
        modelValue: Object,
    },
    data: function(){
      return {
      }
    },
    computed:{
      config:{
        get: function(){
          if (this.modelValue.keepChromosomesOnly==true && this.modelValue.keepRegionsOnly==false){
            return 1;
          }
          else if (this.modelValue.keepChromosomesOnly==false && this.modelValue.keepRegionsOnly==true){
            return 2;
          }
          else {
            return 0;
          }
        },
        set: function(d){
          if (d==0){
            this.$emit('update:modelValue',{
              keepChromosomesOnly:false,
              keepRegionsOnly:false,

            });
          }
          else if (d==1){
            this.$emit('update:modelValue',{
              keepChromosomesOnly:true,
              keepRegionsOnly:false,

            });
          }
          else if (d==2){
            this.$emit('update:modelValue',{
              keepChromosomesOnly:false,
              keepRegionsOnly:true,
            });
          }      
        },
    },
    },
    methods:{
      //CODE
    },
    mounted: function(){
      //CODE
    },
    watch:{
      //CODE
    }, 
}
</script>
