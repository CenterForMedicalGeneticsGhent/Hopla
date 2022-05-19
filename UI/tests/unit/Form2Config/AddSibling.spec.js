import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
    addSibling,
} from './utils';

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let vuetify;
let wrapper;
let params0;
let params1;
let params2;
let expectedConfigText;

beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });
    params0 = {
        N: 0,
        sampleID : "defaultSiblingID0",
        gender : "NA",
        diseaseStatus :  "NA",
        keepLimitIDHardDP :  true,
        keepLimitIDHardAF : true,
    };
    params1 = {
        N: 1,
        sampleID : "defaultSiblingID1",
        gender : "F",
        diseaseStatus :  "NA",
        keepLimitIDHardDP :  false,
        keepLimitIDHardAF : true,
    };
    params2 = {
        N: 2,
        sampleID : "defaultSiblingID2",
        gender : "M",
        diseaseStatus :  "NA",
        keepLimitIDHardDP :  true,
        keepLimitIDHardAF : false,
    };
    expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultSiblingID0',
        )
        .replace(
            'father.ids=',
            'father.ids=NA',
        )
        .replace(
            'mother.ids=',
            'mother.ids=NA',
        )
        .replace(
            'genders=',
            'genders=NA',
        )
        .replace(
            'dp.hard.limit.ids=',
            'dp.hard.limit.ids=defaultSiblingID0',
        )
        .replace(
            'af.hard.limit.ids=',
            'af.hard.limit.ids=defaultSiblingID0',
        )
        ;
}
);


afterEach( function(){
    wrapper.destroy();
}
);


describe('changing sibling inputs should change corresponding values in config', function(){
    test('default inputs', async function(){
        await addSibling(wrapper, params0);

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `gender`', async function(){
        // change params0 object
        params0.gender = "F";
        // change expected config text;
        expectedConfigText = expectedConfigText
            .replace(
                'genders=NA',
                'genders=F',
            )
            ;
        
        await addSibling(wrapper,params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `sample id`', async function(){
        // change params0 object
        params0.sampleID = "newSampleID";
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                /defaultSiblingID0/g,
                'newSampleID',
            )
            ;
        await addSibling(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep dp hard limit id` checkbox', async function(){
        // change params0 object
        params0.keepLimitIDHardDP = false;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'dp.hard.limit.ids=defaultSiblingID0',
                'dp.hard.limit.ids=',
            )
            ;
        await addSibling(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep af hard limit id` checkbox', async function(){
        // change params0 object
        params0.keepLimitIDHardAF = false;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'af.hard.limit.ids=defaultSiblingID0',
                'af.hard.limit.ids=',
            )
            ;
        await addSibling(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `disease status` to `affected`', async function(){
        // change params0 object
        params0.diseaseStatus = 'affected';
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'affected.ids=',
                'affected.ids=defaultSiblingID0',
            )
            ;
        await addSibling(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `disease status` to `nonaffected`', async function(){
        // change params0 object
        params0.diseaseStatus = 'nonaffected';
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'nonaffected.ids=',
                'nonaffected.ids=defaultSiblingID0',
            )
            ;
        await addSibling(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `disease status` to `carrier`', async function(){
        // change params0 object
        params0.diseaseStatus = 'carrier';
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'carrier.ids=',
                'carrier.ids=defaultSiblingID0',
            )
            ;
        await addSibling(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('add multiple siblings', async function(){
        await addSibling(wrapper, params0);
        await addSibling(wrapper, params1);
        await addSibling(wrapper, params2);

        expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultSiblingID0,defaultSiblingID1,defaultSiblingID2',
        )
        .replace(
            'father.ids=',
            'father.ids=NA,NA,NA',
        )
        .replace(
            'mother.ids=',
            'mother.ids=NA,NA,NA',
        )
        .replace(
            'genders=',
            'genders=NA,F,M',
        )
        .replace(
            'dp.hard.limit.ids=',
            'dp.hard.limit.ids=defaultSiblingID0,defaultSiblingID2',
        )
        .replace(
            'af.hard.limit.ids=',
            'af.hard.limit.ids=defaultSiblingID0,defaultSiblingID1',
        )
        ;

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
}
);