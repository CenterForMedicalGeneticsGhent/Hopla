<template>
<v-container>
<v-row>
    <v-col
    class="d-flex justify-center align-center"
    >
        <InputChr v-model="chr" />
    </v-col>
    
    <v-col
    class="d-flex justify-center align-center"
    >
        <InputChrStart v-model="chrStart" />
    </v-col>

    <v-col
    class="d-flex justify-center align-center"
    >
        <InputChrEnd v-model="chrEnd" />
    </v-col>
</v-row>
</v-container>
</template>


<script>
import Vue from 'vue';
import InputChr from "../Inputs/InputChr.vue";
import InputChrStart from "../Inputs/InputChrStart.vue";
import InputChrEnd from "../Inputs/InputChrEnd.vue";


export default Vue.extend({
    name: 'InputRegion',
    props:{
        value: Object,
    },
    components:{
        InputChr,
        InputChrStart,
        InputChrEnd,
    },
    data: function(){
        return{
            chr: this.value.chr,
            chrStart: this.value.chrStart,
            chrEnd: this.value.chrEnd,
        }
    },
    computed:{
        config: function() {
            return {
                chr: this.chr,
                chrStart: this.chrStart,
                chrEnd: this.chrEnd,
            };
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