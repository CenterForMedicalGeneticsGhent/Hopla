import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount} from '@vue/test-utils';
import {
    getConfigText,
    emptyConfigText,
    removeCommentsFromConfig,
} from "./utils";

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let wrapper;
let vuetify;
let InputElment;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // select disease input element
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();
    InputElment = wrapper.findComponent({ name: 'InputInheritance' });
}
);


afterEach( function(){
    wrapper.destroy();
}
);


test("Changing inheritance input changes corresponding config field", async function(){
    // fill in new value
    await InputElment.vm.$emit('input','XLR');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'Inheritance:AD',
        'Inheritance:XLR',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);
