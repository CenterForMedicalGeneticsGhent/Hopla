<template>
<PedigreeGroup
width="100%"
imgType='embryos'
title="Embryos"
imgLicense="Designed by Culmbio from Flaticon"
v-model="embryoList"
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
      v-model="embryoList[col-1]"
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
      <InputHeteroIDs v-model="keepHeteroIDs" />
    </v-col>
  </v-row>
</PedigreeGroup>
</template>

<script>
  import Vue from 'vue';
  import cloneDeep from 'lodash/cloneDeep';
  import PedigreeGroup from "./PedigreeGroup.vue";
  import PatientCardEmbryo from "../PatientCards/PatientCardEmbryo.vue";
  import InputHeteroIDs from "../Inputs/InputHeteroIDs.vue";

  // configEmbryoDefault
  var configEmbryosDefault = {
    sampleID: "",
    gender: "NA",
    keepInformativeIDs: "hide",
    diseaseStatus: "NA",
    keepLimitIDHardDP: "hide",
    keepLimitIDHardAF: "hide",
    keepLimitIDSoftDP: true,
  };

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
        embryoList: this.value.embryoList,
        keepHeteroIDs: this.value.keepHeteroIDs,
        counter:0,
      }
    },
    computed:{
      config: function(){
        return {
          embryoList: this.embryoList,
          keepHeteroIDs: this.keepHeteroIDs,
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
      countEmbryos: function(){
        return this.embryoList.length;
      },
      countRows: function(){
        return Math.ceil(this.countEmbryos()/this.colsMax);
      },
      addEmbryo: function(){
        this.embryoList.push(cloneDeep(configEmbryosDefault));
      },
      removeEmbryo: function(j){
        this.embryoList = this.embryoList.filter((_, index) => index != j);
        this.counter++;
      },
    },
    mounted: function(){
      //code
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