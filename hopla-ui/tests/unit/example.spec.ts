import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { shallowMount } from '@vue/test-utils'
import cloneDeep from 'lodash/cloneDeep'
import { parse } from 'yaml'
import TabConfigFile from '@/components/Tabs/TabConfigFile.vue'
import { config2Form } from '@/components/Parsers/Config2Form'
import {
  templateAdvanced,
  templateParameters,
  templatePedigree
} from '@/components/Templates'

function exportConfigText(config: any): string {
  const wrapper = shallowMount(TabConfigFile, {
    props: config,
    global: {
      stubs: ['OutputDownloadConfig', 'v-container']
    }
  })
  return (wrapper.vm as any).configText
}

describe('Hopla configuration conversion', () => {
  it('exports schema-compatible YAML instead of legacy settings text', () => {
    const configPedigree = cloneDeep(templatePedigree)
    const configParameters = cloneDeep(templateParameters)
    const configAdvanced = cloneDeep(templateAdvanced)
    configPedigree.configParents.father.sampleID = 'FATHER'
    const generatedConfig = exportConfigText({
      configPedigree,
      configParameters,
      configAdvanced
    })
    const settings = parse(generatedConfig)

    expect(generatedConfig).toContain('sample_ids:')
    expect(generatedConfig).not.toContain('sample.ids=')
    expect(settings.sample_ids).toEqual(['FATHER'])
    expect(settings.father_ids).toEqual([null])
    expect(settings.genders).toEqual(['M'])
    expect(settings.af_hard_limit).toBe(0.25)
    expect(settings.keep_chromosomes_only).toBe(true)
    expect(settings.limit_pm_to_p).toBe(true)
    expect(settings.fam_id).toBe('famID')
    expect(settings).not.toHaveProperty('vcf_file')
    expect(settings).not.toHaveProperty('cytoband_file')
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
      { chr: 'chr17', chrStart: 43044294, chrEnd: 43125363 }
    ])
    expect(imported.configAdvanced.remainingFeatures.selfContained).toBe(true)
  })

  it('reconstructs the pedigree of a settings file written without a header', () => {
    const configText = readFileSync(
      resolve(process.cwd(), 'tests/fixtures/legacy-settings.txt'),
      'utf8'
    )

    const imported = config2Form(configText)
    const pedigree = imported.configPedigree

    // Derived from the sample.ids/father.ids/mother.ids columns: the embryos
    // DNA052963 and DNA052966 are the children of DNA052960 x DNA052959, and
    // DNA052959 is in turn the child of U1 x DNA052961.
    expect(pedigree.configParents.father.sampleID).toBe('DNA052960')
    expect(pedigree.configParents.mother.sampleID).toBe('DNA052959')
    expect(pedigree.configGrandParentsMaternal.maternalGrandfather.sampleID).toBe('U1')
    expect(pedigree.configGrandParentsMaternal.maternalGrandmother.sampleID).toBe('DNA052961')
    expect(pedigree.configEmbryos.embryoList.map((d: any) => d.sampleID)).toEqual([
      'DNA052963',
      'DNA052966'
    ])
    expect(pedigree.configSiblings).toEqual([])

    // Relatives outside the analysis keep their form placeholders.
    expect(pedigree.configGrandParentsPaternal.paternalGrandfather.sampleID).toBe('U3')
    expect(pedigree.configGrandParentsPaternal.paternalGrandfather.gender).toBe('M')
    expect(pedigree.configGrandParentsPaternal.paternalGrandmother.gender).toBe('F')

    expect(pedigree.configParents.mother.diseaseStatus).toBe('affected')
    expect(pedigree.configParents.father.diseaseStatus).toBe('nonaffected')
    expect(imported.configParameters.sampleDisease.inheritance).toBe('AD')
    expect(imported.configParameters.sampleDisease.regions).toEqual([
      { chr: 'chr17', chrStart: 43044294, chrEnd: 43125363 }
    ])

    // fam.id is not set in the file, so the form default survives the import.
    expect(pedigree.famID).toBe(templatePedigree.famID)
  })

  it('exports a header-less legacy import as schema-shaped YAML', () => {
    const configText = [
      'vcf.file=/data/trio.vcf.gz',
      'sample.ids=FATHER,MOTHER,EMBRYO',
      'father.ids=NA,NA,FATHER',
      'mother.ids=NA,NA,MOTHER',
      'genders=M,F,NA',
      'dp.soft.limit.ids=EMBRYO',
      'affected.ids=MOTHER'
    ].join('\n')

    const imported = config2Form(configText)
    expect(imported.configPedigree.configParents.father.sampleID).toBe('FATHER')
    expect(imported.configPedigree.configEmbryos.embryoList.map((d: any) => d.sampleID))
      .toEqual(['EMBRYO'])

    const settings = parse(exportConfigText(imported))
    expect(settings.sample_ids).toEqual(['FATHER', 'MOTHER', 'EMBRYO'])
    expect(settings.father_ids).toEqual([null, null, 'FATHER'])
    expect(settings.mother_ids).toEqual([null, null, 'MOTHER'])
    expect(settings.dp_soft_limit_ids).toEqual(['EMBRYO'])
    expect(settings.affected_ids).toEqual(['MOTHER'])
  })

  it('rejects configuration text it cannot turn into a pedigree', () => {
    expect(() => config2Form('vcf.file=/tmp/example.vcf.gz')).toThrow(
      'no sample.ids argument was found'
    )
    expect(() =>
      config2Form(['sample.ids=A,B', 'father.ids=NA,NA', 'mother.ids=NA,NA'].join('\n'))
    ).toThrow('no father.ids or mother.ids relationships were found')
    expect(() => config2Form('x'.repeat(1024 * 1024 + 1))).toThrow(
      'the file is larger than the 1 MB limit'
    )
  })
})
