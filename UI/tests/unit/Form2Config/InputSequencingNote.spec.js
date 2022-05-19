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
let inputSequencingNote;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // Open parameters tab
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();

    // select sequencing note input element
    inputSequencingNote = wrapper.find('#input_sequencing_note');
}
);


afterEach( function(){
    wrapper.destroy();
}
);


test("Changing sequencing note input changes corresponding config field", async function(){
    // fill in new value
    await inputSequencingNote.setValue('test');
    await wrapper.vm.$nextTick();

    // compare expected config text with actual config text
    let configText = await getConfigText(wrapper);
    let expectedConfigText = emptyConfigText.replace(
        'Sequencing note:',
        'Sequencing note:test',
    );

    expect(removeCommentsFromConfig(configText))
    .toEqual(removeCommentsFromConfig(expectedConfigText))
    ;
}
);
