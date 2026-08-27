// @ts-nocheck
import { shallowMount } from '@vue/test-utils'
import cloneDeep from 'lodash/cloneDeep'
import TabConfigFile from '@/components/Tabs/TabConfigFile.vue'
import { config2Form } from '@/components/Parsers/Config2Form'
import {
  templateAdvanced,
  templateParameters,
  templatePedigree
} from '@/components/Templates'

describe('Hopla configuration conversion', () => {
  it('round-trips the default form through the generated settings text', () => {
    const configPedigree = cloneDeep(templatePedigree)
    const configParameters = cloneDeep(templateParameters)
    const configAdvanced = cloneDeep(templateAdvanced)
    const wrapper = shallowMount(TabConfigFile, {
      props: {
        configPedigree,
        configParameters,
        configAdvanced
      },
      global: {
        stubs: ['OutputDownloadConfig', 'v-container']
      }
    })

    const generatedConfig = (wrapper.vm as any).configText
    const importedConfig = config2Form(generatedConfig)

    expect(generatedConfig).toContain('vcf.file=/path/to/file.vcf')
    expect(generatedConfig).toContain('fam.id=famID')
    expect(importedConfig.configPedigree).toEqual(configPedigree)
    expect(importedConfig.configParameters).toEqual(configParameters)
    expect(importedConfig.configAdvanced).toEqual(configAdvanced)
  })

  it('imports representative pedigree and analysis settings', () => {
    const configText = [
      '# paternalGrandfather=PGF',
      '# paternalGrandmother=PGM',
      '# maternalGrandfather=MGF',
      '# maternalGrandmother=MGM',
      '# father=FATHER',
      '# mother=MOTHER',
      '# siblings=SIBLING',
      '# embryos=EMBRYO',
      'vcf.file=/data/family.vcf.gz',
      'sample.ids=PGF,PGM,MGF,MGM,FATHER,MOTHER,SIBLING,EMBRYO',
      'father.ids=NA,NA,NA,NA,PGF,MGF,FATHER,FATHER',
      'mother.ids=NA,NA,NA,NA,PGM,MGM,MOTHER,MOTHER',
      'genders=M,F,M,F,M,F,F,NA',
      'cytoband.file=/data/cytoband.txt',
      'dp.hard.limit.ids=FATHER,MOTHER',
      'af.hard.limit.ids=FATHER,MOTHER',
      'af.hard.limit=.2',
      'dp.soft.limit.ids=EMBRYO',
      'keep.informative.ids=FATHER,MOTHER',
      'keep.hetero.ids=',
      'regions=chr17:43044294-43125363',
      'carrier.ids=SIBLING',
      'affected.ids=MOTHER',
      'nonaffected.ids=FATHER',
      'start.info',
      'Disease:BRCA1',
      'Inheritance:AD',
      'Sequencing note:validation fixture',
      'end.info',
      'baf.ids=EMBRYO',
      'window.size.voting=10000000',
      'keep.chromosomes.only=T',
      'keep.regions.only=F',
      'fam.id=family-1',
      'limit.baf.to.P=F',
      'limit.pm.to.P=T',
      'value.of.P=.15',
      'self.contained=T',
      'regions.flanking.size=2000000'
    ].join('\n')

    const imported = config2Form(configText)

    expect(imported.configPedigree.famID).toBe('family-1')
    expect(imported.configPedigree.configParents.father.sampleID).toBe('FATHER')
    expect(imported.configPedigree.configEmbryos.embryoList[0].sampleID).toBe('EMBRYO')
    expect(imported.configParameters.fileVCF).toBe('/data/family.vcf.gz')
    expect(imported.configParameters.sampleDisease.regions).toEqual([
      { chr: 'chr17', chrStart: '43044294', chrEnd: '43125363' }
    ])
    expect(imported.configAdvanced.remainingFeatures.selfContained).toBe(true)
  })

  it('rejects incomplete and oversized configuration text', () => {
    expect(() => config2Form('vcf.file=/tmp/example.vcf.gz')).toThrow(
      'Missing required configuration field'
    )
    expect(() => config2Form('x'.repeat(1024 * 1024 + 1))).toThrow(
      'Invalid Hopla configuration'
    )
  })
})
