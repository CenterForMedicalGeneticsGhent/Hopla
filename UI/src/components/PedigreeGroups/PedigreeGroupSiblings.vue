<template>
<PedigreeGroup
width="100%"
imgType='siblings'
title="Siblings"
v-model="config"
imgLicense="Designed by FreePlk from Flaticon"
>
  <v-row>
    <v-col
    class="d-flex justify-center align-center"
    v-for="col in countSiblings()"
    :key="col"
    >
      <PatientCardSibling
      :key="col+counter"
      v-if="col<=countSiblings()" 
      v-model="config[col-1]"
      :i="col-1"
      @removeCard="removeSibling(col-1)"
      />
    </v-col>
  </v-row>
  <v-row> <v-col class="d-flex justify-center align-center"> 
    <v-btn
    @click="addSibling()"
    >
      <v-icon>
        mdi-plus
      </v-icon>
      <v-avatar 
      size="32"
      tile
      >
        <v-img
          src="../../assets/siblingNA.png"
        />
      </v-avatar>
    </v-btn>
  </v-col></v-row>
</PedigreeGroup>
</template>

<script>
  import Vue from 'vue';
  import cloneDeep from 'lodash/cloneDeep';
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardSibling from "../PatientCards/PatientCardSibling.vue";

  // configSiblingDefault
  var configSiblingsDefault = {
    sampleID: "",
    gender: "NA",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: true,
    keepLimitIDHardAF: true,
    keepLimitIDSoftDP: "hide",
  };

  export default Vue.extend({
    name: 'PedigreeGroupSiblings',
    components:{
      PedigreeGroup,
      PatientCardSibling,
    },
    props:{
      value: Array,
    },
    data: function() {
      return {
        config: this.value,
        counter: 0,
      }
    },
    computed:{
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
      countSiblings: function(){
        return this.config.length;
      },
      addSibling: function(){
        this.config.push(cloneDeep(configSiblingsDefault));
      },
      removeSibling: function(j){
        this.config = this.config.filter((_, index) => index != j);
        this.counter++;
      },
    },
    mounted: function(){
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
        immediate:true,
      },
    }, 
    })
</script>