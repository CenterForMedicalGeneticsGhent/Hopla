import Vue from 'vue';
import Vuetify from 'vuetify';

import { mount } from '@vue/test-utils';
import {
    getConfigText,
    removeCommentsFromConfig,
    emptyConfigText,
    addEmbryo,
} from './utils';

import FormHopla from '@/components/Forms/FormHopla.vue';


Vue.use(Vuetify);


let vuetify;
let wrapper;
let keepHetero;
let params0;
let params1;
let params2;
let expectedConfigText;

beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });
    let keepHetero = false;
    params0 = {
        N: 0,
        sampleID : "defaultEmbryoID0",
        gender : "NA",
        diseaseStatus :  "NA",
        keepLimitIDSoftDP :  true,
        keepBafProfile : true,
        keepHetero: keepHetero,
    };
    params1 = {
        N: 1,
        sampleID : "defaultEmbryoID1",
        gender : "F",
        diseaseStatus :  "affected",
        keepLimitIDSoftDP :  false,
        keepBafProfile : true,
        keepHetero: keepHetero,
    };
    params2 = {
        N: 2,
        sampleID : "defaultEmbryoID2",
        gender : "M",
        diseaseStatus :  "carrier",
        keepLimitIDSoftDP :  true,
        keepBafProfile : false,
        keepHetero: keepHetero,
    };
    expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultEmbryoID0',
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
            'dp.soft.limit.ids=',
            'dp.soft.limit.ids=defaultEmbryoID0',
        )
        .replace(
            'baf.ids=',
            'baf.ids=defaultEmbryoID0',
        )
        .replace(
            'keep.hetero.ids=',
            'keep.hetero.ids=',
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
        await addEmbryo(wrapper, params0);

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep hetero ID', async function(){
        // change params0 object
        params0.keepHetero = true;
        // change expected config text;
        expectedConfigText = expectedConfigText
            .replace(
                'keep.hetero.ids=',
                'keep.hetero.ids=defaultEmbryoID0',
            )
            ;

            await addEmbryo(wrapper,params0);
            await wrapper.vm.$nextTick();
    
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
        
        await addEmbryo(wrapper,params0);
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
                /defaultEmbryoID0/g,
                'newSampleID',
            )
            ;
        await addEmbryo(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep dp soft limit id` checkbox', async function(){
        // change params0 object
        params0.keepLimitIDSoftDP = false;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'dp.soft.limit.ids=defaultEmbryoID0',
                'dp.soft.limit.ids=',
            )
            ;
        await addEmbryo(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('change `keep baf profile` checkbox', async function(){
        // change params0 object
        params0.keepBafProfile = false;
        // change expected config text
        expectedConfigText = expectedConfigText
            .replace(
                'baf.ids=defaultEmbryoID0',
                'baf.ids=',
            )
            ;
        await addEmbryo(wrapper, params0);
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
                'affected.ids=defaultEmbryoID0',
            )
            ;
        await addEmbryo(wrapper, params0);
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
                'nonaffected.ids=defaultEmbryoID0',
            )
            ;
        await addEmbryo(wrapper, params0);
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
                'carrier.ids=defaultEmbryoID0',
            )
            ;
        await addEmbryo(wrapper, params0);
        await wrapper.vm.$nextTick();

        // compare expected config text with actual config text
        let configText = await getConfigText(wrapper);

        expect(removeCommentsFromConfig(configText))
        .toEqual(removeCommentsFromConfig(expectedConfigText))
        ;
    }
    );
    test('add multiple', async function(){
        await addEmbryo(wrapper, params0);
        await addEmbryo(wrapper, params1);
        await addEmbryo(wrapper, params2);

        expectedConfigText = emptyConfigText.replace(
            'sample.ids=',
            'sample.ids=defaultEmbryoID0,defaultEmbryoID1,defaultEmbryoID2',
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
            'dp.soft.limit.ids=',
            'dp.soft.limit.ids=defaultEmbryoID0,defaultEmbryoID2',
        )
        .replace(
            'baf.ids=',
            'baf.ids=defaultEmbryoID0,defaultEmbryoID1',
        )
        .replace(
            'affected.ids=',
            'affected.ids=defaultEmbryoID1',
        )
        .replace(
            'carrier.ids=',
            'carrier.ids=defaultEmbryoID2',
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