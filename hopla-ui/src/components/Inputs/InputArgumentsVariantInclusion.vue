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
import InputAfHardLimit from "./InputAfHardLimit.vue";

export default {
    name: 'InputArgumentsVariantInclusion',
    emits: ['update:modelValue'],
    props:{
        modelValue: Number,
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
          return this.modelValue;
        },
        set: function(d){
          this.$emit('update:modelValue',d);
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
}
</script>