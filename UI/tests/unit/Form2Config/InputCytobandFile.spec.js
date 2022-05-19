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
let inputCytobandFile;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Open parameters tab
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    // select vcf file input element
    inputCytobandFile = wrapper.find('#input_cytoband_file');
});

afterEach(function(){
    wrapper.destroy();
});


test('Changing cytoband file input changes corresponding config field', async function(){
    // fill in new value
    await inputCytobandFile.setValue('/new/path/to/file');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'cytoband.file=/home/projects/coPGT-M/ref/cytoBand_hg38.txt', 
        'cytoband.file=/new/path/to/file',
        );
    
    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
});