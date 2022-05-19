import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    emptyConfigText,
    removeCommentsFromConfig,
    getConfigText,
} from './utils';

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let vuetify;
let wrapper;
let inputElm;


beforeEach(async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Get the input element
    await wrapper.find('#tab_pedigree').trigger('click');
    await wrapper.vm.$nextTick();
    inputElm = wrapper.find('#input_family_id');
}
);


afterEach( function(){
    wrapper.destroy();
}
);


test("Changing family id input changes corresponding config field", async function(){
    // Fill in new value
    await inputElm.setValue('newFamID');
    await wrapper.vm.$nextTick();

    // Compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'fam.id=famID',
        'fam.id=newFamID',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);


