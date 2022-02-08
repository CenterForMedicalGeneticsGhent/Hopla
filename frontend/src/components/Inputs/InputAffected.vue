<template>
    <v-radio-group
    class="ma-0 pa-0"
    v-model="diseaseStatus2RadioBtnNr"
    v-on:change="handleInput()"
    >
      <v-radio
        label="Not Affected"
        :value="0"
      ></v-radio>
      <v-radio
        label="Affected"
        :value="1"
      ></v-radio>
      <v-radio
        label="Carrier"
        :value="2"
      ></v-radio>
      <v-radio
        label="Unknown"
        :value="3"
      ></v-radio>
    </v-radio-group>
</template>


<script>
var diseaseStatusOptions = [
  "nonaffected",
  "affected",
  "carrier",
  "NA",
];

export default {
    props:{
        value: String,
    },
    data: function(){
        let d  = {
            diseaseStatus: this.value,
        };
        return d;
    },
    computed:{
      diseaseStatus2RadioBtnNr: {
        get: function(){ 
          for (let i=0; i<diseaseStatusOptions.length;i++){
            if (this.diseaseStatus==diseaseStatusOptions[i]){
              return i;
            }
          }
          return 3;
        },
        set: function(i){
          this.diseaseStatus = diseaseStatusOptions[i];
        }
      }
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.diseaseStatus);
      },
    },
    mounted: function(){
        //CODE
    }
}
</script>
