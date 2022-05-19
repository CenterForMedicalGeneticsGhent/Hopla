<template>
    <v-radio-group
    id="input_affected"
    class="ma-0 pa-0"
    v-model="diseaseStatus2RadioBtnNr"
    dense
    >
      <v-radio
        label="Not Affected"
        :value="0"
        class=""
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
    name:"InputAffected",
    props:{
        value: String,
    },
    data: function(){
        return {};
    },
    computed:{
      diseaseStatus:{
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',d);
        },
      },
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
    },
    mounted: function(){
        //CODE
    }
}
</script>
