import Vue from 'vue';
import Vuetify from "vuetify";

import { mount } from '@vue/test-utils';
import { 
    getConfigText, 
    removeCommentsFromConfig,
    emptyConfigText
} from './utils';

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let wrapper;
let vuetify;


beforeEach(function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });
});

afterEach(function(){
    wrapper.destroy();
});



test('Form with empty input returns config with some defaults',async function(){
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText;

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
});