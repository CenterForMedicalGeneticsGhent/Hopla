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
            afHardLimit: this.value,
        }
    },
    computed:{
        configWatcher: {
            get: function(){
            return `
                ${JSON.stringify(this.afHardLimit)}
            `;
            }
        },
    },
    methods:{
      handleInput: function(){
        this.$emit('input',this.afHardLimit);
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