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
let inputWindowSizeVoting;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Open parameters tab
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    // select window size voting input element
    inputWindowSizeVoting = wrapper.find('#input_window_size_voting');
});

afterEach( function(){
    wrapper.destroy();
});


test("Changing window size voting input correctly changes corresponding config field", async function(){
    // fill in new value
    await inputWindowSizeVoting.setValue(20000000);
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'window.size.voting=1000000',
        'window.size.voting=2000000',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
});


describe("Trying to change window size voting input to invalid value should not change config field or input field", function(){
    test("values smaller than zero", async function(){
        // fill in new value
        await inputWindowSizeVoting.setValue(-1);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'window.size.voting=1000000',
            'window.size.voting=1000000',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    });

    test("values that are not a number", async function(){
        // fill in new value
        await inputWindowSizeVoting.setValue('not a number');
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'window.size.voting=1000000',
            'window.size.voting=1000000',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    });
});
