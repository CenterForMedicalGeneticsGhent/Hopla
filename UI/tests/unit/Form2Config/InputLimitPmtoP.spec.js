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
    inputElm = await wrapper.find("#input_limit_pm_to_p");
}
);


afterEach(function(){
    wrapper.destroy();
}
);


test('Toggeling checkbox changes corresponding config fiels', async function(){
    // fill in new value
    await inputElm.setChecked(false);
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'limit.pm.to.P=T',
        'limit.pm.to.P=F',
    );
    
    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);

