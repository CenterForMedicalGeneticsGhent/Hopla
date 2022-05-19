import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
    addMaternalGrandmother,
} from './utils';

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let vuetify;
let wrapper;
let params;
let expectedConfigText;

beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });
    params = {
        sampleID : "defaultMaternalGrandmotherID",
        gender : "F",
        keepInformativeIDs : false,
        diseaseStatus :  "NA",
        keepLimitIDHardDP :  true,
        keepLimitIDHardAF : true,
    };
    expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultMaternalGrandmotherID,U2',
        )
        .replace(
            'father.ids=',
            'father.ids=NA,NA',
        )
        .replace(
            'mother.ids=',
            'mother.ids=NA,defaultMaternalGrandmotherID',
        )
        .replace(
            'genders=',
            'genders=F,F',
        )
        .replace(
            'dp.hard.limit.ids=',
            'dp.hard.limit.ids=defaultMaternalGrandmotherID,U2',
        )
        .replace(
            'af.hard.limit.ids=',
            'af.hard.limit.ids=defaultMaternalGrandmotherID,U2',
        )
        .replace(
            'keep.informative.ids=',
            'keep.informative.ids=U2',
        )
        ;
}
);


afterEach( function(){
    wrapper.destroy();
}
);


describe('Changing `maternal grandmother` mother inputs should change corresponding values in config', function(){
    test('default inputs', async function(){
        await addMaternalGrandmother(wrapper, params);

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `sample id`', async function(){
        // change params object
        params.sampleID = "newSampleID";
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                /defaultMaternalGrandmotherID/g,
                'newSampleID',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep informative id` checkbox', async function(){
        // change params object
        params.keepInformativeIDs = true;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'keep.informative.ids=U2',
                'keep.informative.ids=defaultMaternalGrandmotherID,U2',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep dp hard limit id` checkbox', async function(){
        // change params object
        params.keepLimitIDHardDP = false;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'dp.hard.limit.ids=defaultMaternalGrandmotherID,U2',
                'dp.hard.limit.ids=U2',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep af hard limit id` checkbox', async function(){
        // change params object
        params.keepLimitIDHardAF = false;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'af.hard.limit.ids=defaultMaternalGrandmotherID,U2',
                'af.hard.limit.ids=U2',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `disease status` to `affected`', async function(){
        // change params object
        params.diseaseStatus = 'affected';
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'affected.ids=',
                'affected.ids=defaultMaternalGrandmotherID',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `disease status` to `nonaffected`', async function(){
        // change params object
        params.diseaseStatus = 'nonaffected';
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'nonaffected.ids=',
                'nonaffected.ids=defaultMaternalGrandmotherID',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `disease status` to `carrier`', async function(){
        // change params object
        params.diseaseStatus = 'carrier';
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'carrier.ids=',
                'carrier.ids=defaultMaternalGrandmotherID',
            )
            ;
        await addMaternalGrandmother(wrapper, params);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
}
);