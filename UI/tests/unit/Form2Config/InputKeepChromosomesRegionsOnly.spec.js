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


let vuetify;
let wrapper;
let inputElm;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    // select input element
    await wrapper.find('#tab_parameters').trigger('click');
    await wrapper.vm.$nextTick();
    inputElm = wrapper.find('#input_keep_chromosomes_regions_only');
}
);


afterEach( function(){
    wrapper.destroy();
}
);


describe('changing input on chromosomes or regions to keep should be reflected in config', function(){
    test('show everyhting', async function(){
        await inputElm.find("#input_keep_chromosomes_regions_only__everything").setChecked(true);
        await wrapper.vm.$nextTick();

        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'keep.chromosomes.only=T',
            'keep.chromosomes.only=F',
        )
        .replace(
            'keep.regions.only=F',
            'keep.regions.only=F',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );

    test('show chromosomes only', async function(){
        await inputElm.find("#input_keep_chromosomes_regions_only__chromosomes").setChecked(true);
        await wrapper.vm.$nextTick();

        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'keep.chromosomes.only=T',
            'keep.chromosomes.only=T',
        )
        .replace(
            'keep.regions.only=F',
            'keep.regions.only=F',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );


    test('show regions only', async function(){
        await inputElm.find("#input_keep_chromosomes_regions_only__regions").setChecked(true);
        await wrapper.vm.$nextTick();

        let configText = await getConfigText(wrapper);
        let expectedConfigText = emptyConfigText.replace(
            'keep.chromosomes.only=T',
            'keep.chromosomes.only=F',
        )
        .replace(
            'keep.regions.only=F',
            'keep.regions.only=T',
        );

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
}
);