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
let inputChr;
let inputChrStart;
let inputChrEnd;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // select input element
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    await wrapper.find('#input_add_region').trigger('click');
    await wrapper.vm.$nextTick();
       
    inputChr = await wrapper.findComponent({name:'InputChr'});
    inputChrStart = await wrapper.find('#input_chr_start');
    inputChrEnd = await wrapper.find('#input_chr_end');
}
);


afterEach( async function(){
    wrapper.destroy();
}
);


test('Adding regions changes corresponding config fiels', async function(){
    // fill in new value
    await inputChr.vm.$emit('input', 'chr2');
    await inputChrStart.setValue('3');
    await inputChrEnd.setValue('4');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'regions=',
        'regions=chr2:3-4',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);