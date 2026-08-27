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
import InputChr from "../Inputs/InputChr.vue";
import InputChrStart from "../Inputs/InputChrStart.vue";
import InputChrEnd from "../Inputs/InputChrEnd.vue";


export default {
    name: 'InputRegion',
    emits: ['update:modelValue'],
    props:{
        modelValue: Object,
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
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
    },
    methods:{
      //CODE
    },
    watch:{
      //CODE
    },
}
</script>