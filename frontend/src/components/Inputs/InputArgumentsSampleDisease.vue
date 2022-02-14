<template>
<v-container>
<v-card>
    <v-card-title>
        Sample / Disease Annotation
    </v-card-title>
    <v-card-text>
        <InputRegions v-model="regions" />

        <v-row>
          <v-col class="d-flex justify-center align-center">
            <InputDisease v-model="disease" />
          </v-col>
          <v-col class="d-flex justify-center align-center">
            <InputInheritance v-model="inheritance" />
          </v-col>
          <v-col class="d-flex justify-center align-center">
            <InputSequencingNote v-model="sequencingNote" />
          </v-col>
        </v-row>
    </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';
import InputRegions from "./InputRegions.vue";
import InputDisease from "./InputDisease.vue";
import InputInheritance from "./InputInheritance.vue";
import InputSequencingNote from "./InputSequencingNote.vue";

export default Vue.extend({
    name: 'InputArgumentsSampleDisease',
    props:{
        value: Object,
    },
    components:{
      InputRegions,
      InputDisease,
      InputInheritance,
      InputSequencingNote,
    },
    data: function(){
        return{
          regions:this.value.regions,
          disease: this.value.disease,
          inheritance: this.value.inheritance,
          sequencingNote: this.value.sequencingNote,
        }
    },
    computed:{
      config: {
            get: function(){
            return {
              regions:this.regions,
              disease: this.disease,
              inheritance: this.inheritance,
              sequencingNote: this.sequencingNote,
            }
            }
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