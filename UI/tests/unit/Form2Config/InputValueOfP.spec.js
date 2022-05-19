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


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // select input element
    await wrapper.find('#tab_advanced').trigger('click');
    await wrapper.vm.$nextTick();
    inputElm = await wrapper.find("#input_value_of_p");
}
);


afterEach(function(){
    wrapper.destroy();
}
);


test('Changing to valid value of P input changes corresponding config fiels', async function(){
    // fill in new value
    await inputElm.setValue('0.5');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'value.of.P=0.15',
        'value.of.P=0.5',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);


describe('Changing to invalid value of P input does not change corresponding config fiels', function(){
    let invalidValues = [
        'not a number',
        -1,
        1.1,
    ];
    for (let value of invalidValues) {
        test(`${value}`, async function(){
            // fill in new value
            await inputElm.setValue(value);
            await wrapper.vm.$nextTick();

            // compare expected config text with actual config text
            let configText = await getConfigText(wrapper);
            let expectedConfigText = emptyConfigText.replace(
                'value.of.P=0.15',
                'value.of.P=0.15',
            );

            expect(removeCommentsFromConfig(configText))
            .toEqual(removeCommentsFromConfig(expectedConfigText))
            ;
        }
        );
    }
}
);