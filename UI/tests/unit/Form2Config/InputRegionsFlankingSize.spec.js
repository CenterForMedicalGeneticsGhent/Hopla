import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
} from './utils';

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let wrapper;
let vuetify;
let inputElm;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // select input element
    await wrapper.find('#tab_advanced').trigger('click');
    await wrapper.vm.$nextTick();
    inputElm = await wrapper.findComponent({name:'InputRegionsFlankingSize'});
}
);


afterEach(function(){
    wrapper.destroy();
}
);


test("Changing regions flanking size input changes corresponding config field", async function(){
    // fill in new value
    await inputElm.vm.$emit('input', 2000000);
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'regions.flanking.size=1000000',
        'regions.flanking.size=2000000',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);