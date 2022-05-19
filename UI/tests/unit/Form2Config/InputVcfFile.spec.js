import Vue from 'vue';
import Vuetify from "vuetify";

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    emptyConfigText,
    removeCommentsFromConfig,
} from "./utils";

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);

let vuetify;
let wrapper;
let inputVcfFile;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Open parameters tab
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    // select vcf file input element
    inputVcfFile = wrapper.find('#input_vcf_file');
});

afterEach(function(){
    wrapper.destroy();
});


test('Changing vcf file input changes corresponding config field', async function(){
    // fill in new value
    await inputVcfFile.setValue('/new/path/to/file.vcf');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'vcf.file=/path/to/file.vcf', 
        'vcf.file=/new/path/to/file.vcf',
        );
    
    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
});