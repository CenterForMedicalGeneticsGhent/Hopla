<template>
<v-container>
<v-card>
    <v-card-title>
        Variant Inclusion Arguments
    </v-card-title>
    <v-card-text>
        <InputAfHardLimit v-model="afHardLimit" />
    </v-card-text>
</v-card>
</v-container>
</template>


<script>
import Vue from 'vue';
import InputAfHardLimit from "./InputAfHardLimit.vue";

export default Vue.extend({
    name: 'InputArgumentsVariantInclusion',
    props:{
        value: Number,
    },
    components:{
      InputAfHardLimit,
    },
    data: function(){
      return{
      }
    },
    computed:{
      afHardLimit: {
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