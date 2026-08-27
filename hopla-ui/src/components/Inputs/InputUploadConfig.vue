<template>
<v-container>
    <v-file-input
    accept=".txt,text/plain"
    placeholder="Upload Config"
    density="compact"
    prepend-inner-icon="mdi-upload"
    prepend-icon=""
    rounded
    variant="filled"
    :error-messages="uploadError"
    @update:model-value="upload"
    />
</v-container>
</template>


<script>
import {config2Form} from "../Parsers/Config2Form";

export default {
    emits: ['updateConfig'],
    props:{
    },
    data: function(){
        return {
            uploadError: "",
        }
    },
    computed:{
    },
    methods:{
        emitNewConfig: function (data){
            this.$emit('updateConfig', data);
        },
        upload: function(files){
            this.uploadError = "";
            var emit=this.emitNewConfig;
            var setError = (message) => {
                this.uploadError = message;
            };
            var file = Array.isArray(files) ? (files[0] || null) : files;
            if (file!=null){
                if (file.size > 1024 * 1024) {
                    setError("Configuration files must be 1 MB or smaller.");
                    return;
                }
                if (!file.name.toLowerCase().endsWith(".txt")) {
                    setError("Choose a Hopla .txt configuration file.");
                    return;
                }
                var fileReader=new FileReader();
                fileReader.onerror=function(){
                    setError("The configuration file could not be read.");
                };
                fileReader.onload=function(){
                    try {
                        var configText = String(fileReader.result);
                        let newConfig = config2Form(configText);
                        emit(newConfig);
                    }
                    catch (error) {
                        var reason = String(error.message || "").replace(/\.$/, "");
                        setError(reason === ""
                            ? "This is not a valid Hopla configuration."
                            : `This is not a valid Hopla configuration: ${reason}.`);
                    }
                }
                fileReader.readAsText(file);
            }
        },
    },
    watch:{
    },
}
</script>
