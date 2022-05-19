import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
} from "./utils"

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let vuetify;
let wrapper;
let inputAfHardLimit;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Open parameters tab
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    // select af hard limit input element
    inputAfHardLimit = wrapper.find('#input_af_hard_limit');
});

afterEach( function(){
    wrapper.destroy();
});


test("Changing af hard limit input changes corresponding config field", async function(){
    // fill in new value
    await inputAfHardLimit.setValue('0.5');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'af.hard.limit=0.25',
        'af.hard.limit=0.5',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
});

describe("Trying to change af hard limit input to invalid value should not change config field or input field", function(){
    test("values smaller than 0", async function(){
        // fill in new value
        await inputAfHardLimit.setValue('-0.5');
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'af.hard.limit=0.25',
            'af.hard.limit=0.25',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    });

    test("values greater than 1", async function(){
        // fill in new value
        await inputAfHardLimit.setValue('1.01');
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'af.hard.limit=0.25',
            'af.hard.limit=0.25',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    });

    test("values that are not numbers", async function(){
        // fill in new value
        await inputAfHardLimit.setValue('not a number');
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'af.hard.limit=0.25',
            'af.hard.limit=0.25',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    });
});