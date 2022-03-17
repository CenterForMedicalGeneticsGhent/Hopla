<template>
<v-container>
<v-row
align="center"
justify="center"
class="mt-4"
>
    <v-col
    class="d-flex justify-center align-center"
    >
        <InputChr v-model="config.chr" />
    </v-col>
    
    <v-col
    class="d-flex justify-center align-center"
    >
        <InputChrStart v-model="config.chrStart" />
    </v-col>

    <v-col
    class="d-flex justify-center align-center"
    >
        <InputChrEnd v-model="config.chrEnd" />
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
        }
    },
    computed:{
        config:{
            get: function(){
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
            },
        },
    },
    methods:{
      //CODE
    },
    watch:{
      //CODE
    },
})
</script>