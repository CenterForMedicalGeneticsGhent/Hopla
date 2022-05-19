import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
    addPaternalGrandmother,
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
        sampleID : "defaultPaternalGrandmotherID",
        gender : "F",
        keepInformativeIDs : false,
        diseaseStatus :  "NA",
        keepLimitIDHardDP :  true,
        keepLimitIDHardAF : true,
    };
    expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultPaternalGrandmotherID,U1',
        )
        .replace(
            'father.ids=',
            'father.ids=NA,NA',
        )
        .replace(
            'mother.ids=',
            'mother.ids=NA,defaultPaternalGrandmotherID',
        )
        .replace(
            'genders=',
            'genders=F,M',
        )
        .replace(
            'dp.hard.limit.ids=',
            'dp.hard.limit.ids=defaultPaternalGrandmotherID,U1',
        )
        .replace(
            'af.hard.limit.ids=',
            'af.hard.limit.ids=defaultPaternalGrandmotherID,U1',
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


describe('Changing paternal grandmother mother inputs should change corresponding values in config', function(){
    test('default inputs', async function(){
        await addPaternalGrandmother(wrapper, params);

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
                /defaultPaternalGrandmotherID/g,
                'newSampleID',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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
                'keep.informative.ids=defaultPaternalGrandmotherID,U1',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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
                'dp.hard.limit.ids=defaultPaternalGrandmotherID,U1',
                'dp.hard.limit.ids=U1',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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
                'af.hard.limit.ids=defaultPaternalGrandmotherID,U1',
                'af.hard.limit.ids=U1',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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
                'affected.ids=defaultPaternalGrandmotherID',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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
                'nonaffected.ids=defaultPaternalGrandmotherID',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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
                'carrier.ids=defaultPaternalGrandmotherID',
            )
            ;
        await addPaternalGrandmother(wrapper, params);
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