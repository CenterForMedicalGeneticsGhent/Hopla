<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
imgLicense="Designed by Culmbio from Flaticon"
v-model="config.embryoList"
>
  <v-row>
    <v-col
    class="d-flex justify-center align-center"
    v-for="col in countEmbryos()"
    :key="col"
    >
      <PatientCardEmbryo
      :key="col+counter"
      v-if="col<=countEmbryos()" 
      v-model="config.embryoList[col-1]"
      :i="col-1"
      @removeCard="removeEmbryo(col-1)"
      />
    </v-col>
  </v-row>
  <v-row
  align="center"
  justify="center"
  >
    <v-col class="d-flex justify-center align-center">
    </v-col> 
    <v-col class="d-flex justify-center align-center"> 
      <v-btn
      id="input_embryo_add"
      @click="addEmbryo()"
      >
        <v-icon>
          mdi-plus
        </v-icon>
        <v-avatar 
        size="32"
        tile
        >
          <v-img
            src="../../assets/embryos.png"
          />
        </v-avatar>
      </v-btn>
    </v-col>

    <v-col class="d-flex justify-center align-center">
      <InputHeteroIDs v-model="config.keepHeteroIDs" />
    </v-col>
  </v-row>
</PedigreeGroup>
</template>

<script>
  //Imports
  import Vue from 'vue';
  import cloneDeep from 'lodash/cloneDeep';

  // Components
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardEmbryo from "../PatientCards/PatientCardEmbryo.vue";
  import InputHeteroIDs from "../Inputs/InputHeteroIDs.vue";

  // Templates
  import {templateEmbryo} from "../Templates";
  var configEmbryosDefault = cloneDeep(templateEmbryo);
  configEmbryosDefault.sampleID="embryoID";

  

  export default Vue.extend({
    name: 'PedigreeGroupEmbryos',
    components:{
      PedigreeGroup,
      PatientCardEmbryo,
      InputHeteroIDs,
    },
    props:{
      value: Object,
    },
    data: function() {
      return {
        counter:0,
      }
    },
    computed:{
      config:{
        get: function(){
          return this.value;
        },
        set: function(d){
          this.$emit('input',this.config);
        },
      },
    },
    methods:{
      countEmbryos: function(){
        return this.config.embryoList.length;
      },
      countRows: function(){
        return Math.ceil(this.countEmbryos()/this.colsMax);
      },
      addEmbryo: function(){
        this.config.embryoList.push(cloneDeep(configEmbryosDefault));
      },
      removeEmbryo: function(j){
        this.config.embryoList = this.config.embryoList.filter((_, index) => index != j);
        this.counter++;
      },
    },
    mounted: function(){
      //code
    },
    watch:{
      //CODE
    },  
    })
</script>