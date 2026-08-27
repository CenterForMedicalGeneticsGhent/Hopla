<template>
<v-container>
<v-card
flat
>
    <v-row
    align="center"
    justify="center"
    v-if="regions.length==0"
    >
        <v-col class="d-flex justify-center align-center">
            <v-btn
            density="compact"
            depressed
            color="green"
            @click="addRegion()"
            >
                Add Region
            </v-btn>
        </v-col>
    </v-row>

    <v-row
    align="center"
    justify="center"
    >
        <v-col>
            <InputRegion
            v-for="(region,index) in regions"
            :key="index"
            v-model="regions[index]"
            />
        </v-col>

        <v-col align="right" class="mr-3">
            <v-btn
            v-if="regions.length>0"
            density="compact"
            depressed
            color="error"
            @click="removeRegion()"
            >
                Remove Region
            </v-btn>
        </v-col>
    </v-row>
</v-card>
</v-container>
</template>


<script>
import cloneDeep from 'lodash/cloneDeep';
import InputRegion from "./InputRegion.vue";

//regionDefault
var regionDefault = {
    chr: "chr1",
    chrStart: 1,
    chrEnd: 99999999,
}

export default {
    name: 'InputRegions',
    emits: ['update:modelValue'],
    props:{
        modelValue: Array,
    },
    components:{
        InputRegion,
    },
    data: function(){
        return{
        }
    },
    computed:{
        regions:{
            get: function(){
                return this.modelValue;
            },
            set: function(d){
                this.$emit('update:modelValue',d);
            },
        },
    },
    methods:{
      removeRegion: function(){
          this.regions=[];
      },
      addRegion: function(){
          this.regions=[cloneDeep(regionDefault)];
      },
    },
    mounted:function(){
        //CODE
    },
    watch:{
      //CODE
    },
}
</script>