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
let expectedConfigText;
let paramsRegions;
let paramsDisease;
let paramsWindowSizeVoting;
let paramsInheritance;
let paramsValueOfP;
let paramsRegionsFlankingSize;
let paramsSequencingNote;
let paramsVcfFile;
let paramsKeepChromosomesRegionsOnly;
let paramsAfHardLimit;
let paramsFamilyID;
let paramsCytobandFile;
let paramsLimitPmtoP;
let paramsPaternalGrandfather;
let paramsPaternalGrandmother;
let paramsMaternalGrandfather;
let paramsMaternalGrandmother;
let paramsFather;
let paramsMother;
let paramsChild0;
let paramsChild1;
let paramsChild2;
let paramsEmbryo0;
let paramsEmbryo1;
let paramsEmbryo2;


beforeEach( async function(){
    vuetify = new Vuetify();
    wrapper = mount(FormHopla, {
        vuetify,
    });

    expectedConfigText = emptyConfigText
	.replace(
        	'father.ids=',
        	'father.ids=',
	)
	.replace(
        	'mother.ids=',
        	'mother.ids=',
	)
	.replace(
        	'genders=',
        	'genders=',
	)
	.replace(
        	'cytoband.file=/home/projects/coPGT-M/ref/cytoBand_hg38.txt',
        	'cytoband.file=/home/projects/coPGT-M/ref/cytoBand_hg38.txt',
	)
	.replace(
        	'dp.hard.limit.ids=',
        	'dp.hard.limit.ids=',
	)
	.replace(
        	'af.hard.limit.ids=',
        	'af.hard.limit.ids=',
	)
	.replace(
        	'af.hard.limit=0.25',
        	'af.hard.limit=0.25',
	)
	.replace(
        	'dp.soft.limit.ids=',
        	'dp.soft.limit.ids=',
	)
	.replace(
        	'keep.informative.ids=',
        	'keep.informative.ids=',
	)
	.replace(
        	'keep.hetero.ids=',
        	'keep.hetero.ids=',
	)
	.replace(
        	'regions=',
        	'regions=',
	)
	.replace(
        	'reference.ids=',
        	'reference.ids=',
	)
	.replace(
        	'carrier.ids=',
        	'carrier.ids=',
	)
	.replace(
        	'affected.ids=',
        	'affected.ids=',
	)
	.replace(
        	'nonaffected.ids=',
        	'nonaffected.ids=',
	)
	.replace(
        	'start.info',
        	'start.info',
	)
	.replace(
        	'Disease:',
        	'Disease:',
	)
	.replace(
        	'Inheritance:AD',
        	'Inheritance:AD',
	)
	.replace(
        	'Sequencing note:',
        	'Sequencing note:',
	)
	.replace(
        	'end.info',
        	'end.info',
	)
	.replace(
        	'baf.ids=',
        	'baf.ids=',
	)
	.replace(
        	'window.size.voting=10000000',
        	'window.size.voting=10000000',
	)
	.replace(
        	'keep.chromosomes.only=T',
        	'keep.chromosomes.only=T',
	)
	.replace(
        	'keep.regions.only=F',
        	'keep.regions.only=F',
	)
	.replace(
        	'fam.id=famID',
        	'fam.id=famID',
	)
	.replace(
        	'limit.baf.to.P=F',
        	'limit.baf.to.P=F',
	)
	.replace(
        	'limit.pm.to.P=T',
        	'limit.pm.to.P=T',
	)
	.replace(
        	'value.of.P=0.15',
        	'value.of.P=0.15',
	)
	.replace(
        	'self.contained=T',
        	'self.contained=T',
	)
	.replace(
        	'regions.flanking.size=1000000',
        	'regions.flanking.size=1000000',
	)
	;
}
);


afterEach( function(){
    wrapper.destroy();
}
);


describe('Filling in multiple fields of the form', function(){
    test('Full form', async function(){
        //CODE
    }
    );
}
);
