<template>
<v-container>
<v-card>
    <v-card-title>
        Sample / Disease Annotation
    </v-card-title>
    <v-card-text>
        <InputRegions v-model="config.regions" />

        <v-row>
          <v-col class="d-flex justify-center align-center">
            <InputDisease v-model="config.disease" />
          </v-col>
          <v-col class="d-flex justify-center align-center">
            <InputInheritance v-model="config.inheritance" />
          </v-col>
          <v-col class="d-flex justify-center align-center">
            <InputSequencingNote v-model="config.sequencingNote" />
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
    mounted:function(){
      //CODE
    },
    watch:{
      //CODE
    },
})
</script>