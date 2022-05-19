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
            id="input_add_region"
            dense
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
            dense
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
import Vue from 'vue';
import cloneDeep from 'lodash/cloneDeep';
import InputRegion from "./InputRegion.vue";

//regionDefault
var regionDefault = {
    chr: "chr1",
    chrStart: 1,
    chrEnd: 99999999,
}

export default Vue.extend({
    name: 'InputRegions',
    props:{
        value: Array,
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
                return this.value;
            },
            set: function(d){
                this.$emit('input',d);
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
})
</script>