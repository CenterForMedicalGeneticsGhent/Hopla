<template>
    <v-radio-group
    class="ma-0 pa-0"
    v-model="config"
    dense
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
import Vue from 'vue';


export default Vue.extend({
    name:"InputKeepChromosomesRegionsOnly",
    props:{
        value: Object,
    },
    data: function(){
      return {
      }
    },
    computed:{
      config:{
        get: function(){
          if (this.value.keepChromosomesOnly==true && this.value.keepRegionsOnly==false){
            return 1;
          }
          else if (this.value.keepChromosomesOnly==false && this.value.keepRegionsOnly==true){
            return 2;
          }
          else {
            return 0;
          }
        },
        set: function(d){
          console.log(d)
          if (d==0){
            this.$emit('input',{
              keepChromosomesOnly:false,
              keepRegionsOnly:false,

            });
          }
          else if (d==1){
            this.$emit('input',{
              keepChromosomesOnly:true,
              keepRegionsOnly:false,

            });
          }
          else if (d==2){
            this.$emit('input',{
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
})
</script>
