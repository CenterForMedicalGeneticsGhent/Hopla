<template>
<v-container>
    <v-file-input
    placeholder="Upload Config"
    dense
    prepend-inner-icon="mdi-upload"
    prepend-icon=""
    rounded
    filled
    @change="upload"
    />
</v-container>
</template>


<script>
import {config2Form} from "../Parsers/Config2Form";

export default {
    props:{
    },
    data: function(){
        return {
        }
    },
    computed:{
    },
    methods:{
        emitNewConfig: function (data){
            this.$emit('updateConfig', data);
        },
        upload: function(event){
            var emit=this.emitNewConfig;
            if (event!=null){
                var fileReader=new FileReader();
                fileReader.readAsText(event);
                fileReader.onload=function(){
                    var configText = fileReader.result;
                    let newConfig = config2Form(configText);
                    emit(newConfig);
                }
                
            }
        },
    },
    watch:{
    },
}
</script>
