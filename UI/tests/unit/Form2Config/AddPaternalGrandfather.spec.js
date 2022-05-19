import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
    addPaternalGrandfather,
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
        sampleID : "defaultPaternalGrandfatherID",
        gender : "M",
        keepInformativeIDs : false,
        diseaseStatus :  "NA",
        keepLimitIDHardDP :  true,
        keepLimitIDHardAF : true,
    };
    expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultPaternalGrandfatherID,U1',
        )
        .replace(
            'father.ids=',
            'father.ids=NA,defaultPaternalGrandfatherID',
        )
        .replace(
            'mother.ids=',
            'mother.ids=NA,NA',
        )
        .replace(
            'genders=',
            'genders=M,M',
        )
        .replace(
            'dp.hard.limit.ids=',
            'dp.hard.limit.ids=defaultPaternalGrandfatherID,U1',
        )
        .replace(
            'af.hard.limit.ids=',
            'af.hard.limit.ids=defaultPaternalGrandfatherID,U1',
        )
        .replace(
            'keep.informative.ids=',
            'keep.informative.ids=U1',
        )
        ;
}
);


afterEach( function(){
    wrapper.destroy();
}
);


describe('Changing paternal grandfather inputs should change corresponding values in config', function(){
    test('default inputs', async function(){
        await addPaternalGrandfather(wrapper, params);

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
                /defaultPaternalGrandfatherID/g,
                'newSampleID',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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
                'keep.informative.ids=U1',
                'keep.informative.ids=defaultPaternalGrandfatherID,U1',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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
                'dp.hard.limit.ids=defaultPaternalGrandfatherID,U1',
                'dp.hard.limit.ids=U1',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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
                'af.hard.limit.ids=defaultPaternalGrandfatherID,U1',
                'af.hard.limit.ids=U1',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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
                'affected.ids=defaultPaternalGrandfatherID',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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
                'nonaffected.ids=defaultPaternalGrandfatherID',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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
                'carrier.ids=defaultPaternalGrandfatherID',
            )
            ;
        await addPaternalGrandfather(wrapper, params);
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