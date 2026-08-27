declare module '@/components/Parsers/Config2Form' {
  export function config2Form(configText: string): any
}

declare module '@/components/Parsers/Form2Settings' {
  export function form2Settings(
    configPedigree: any,
    configParameters: any,
    configAdvanced: any
  ): any
  export function form2SettingsYaml(
    configPedigree: any,
    configParameters: any,
    configAdvanced: any
  ): string
}

declare module '@/components/Templates' {
  export const templateAdvanced: any
  export const templateParameters: any
  export const templatePedigree: any
}
