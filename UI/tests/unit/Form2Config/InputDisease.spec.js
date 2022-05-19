import Vue from 'vue';
import Vuetify from "vuetify";

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
} from "./utils";

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let vuetify;
let wrapper;
let inputDisease;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Open parameters tab
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    // select disease input element
    inputDisease = wrapper.find('#input_disease');
});

afterEach( function(){
    wrapper.destroy();
});


test("Changing disease input changes corresponding config field", async function(){
    // fill in new value
    await inputDisease.setValue('test');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'Disease:',
        'Disease:test',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
});