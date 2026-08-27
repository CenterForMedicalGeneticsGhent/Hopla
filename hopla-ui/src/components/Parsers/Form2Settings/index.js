import { stringify } from "yaml";
import {
  parseAffectedIDs,
  parseAfHardLimitIDs,
  parseBafIDs,
  parseCarrierIDs,
  parseDpHardLimitIDs,
  parseDpSoftLimitIDs,
  parseFatherIDs,
  parseGenders,
  parseKeepHeteroIDs,
  parseKeepInformativeIDs,
  parseMotherIDs,
  parseNonAffectedIDs,
  parseSampleIDs,
} from "../Form2Config";

function splitIDs(value, nullable = false) {
  if (!value) {
    return [];
  }

  return value.split(",").map(function(token) {
    const trimmed = token.trim();
    return nullable && trimmed === "NA" ? null : trimmed;
  }).filter(function(token) {
    return token !== "";
  });
}

function numberValue(value) {
  return typeof value === "number" ? value : Number(value);
}

function buildInfo(sampleDisease) {
  return [
    ["Disease", sampleDisease.disease],
    ["Inheritance", sampleDisease.inheritance],
    ["Sequencing note", sampleDisease.sequencingNote],
  ].filter(function(entry) {
    return entry[1] !== "";
  }).map(function(entry) {
    return `${entry[0]}: ${entry[1]}`;
  });
}

export function form2Settings(configPedigree, configParameters, configAdvanced) {
  const sampleDisease = configParameters.sampleDisease;
  const merlinProfiles = configParameters.merlinProfiles;
  const keepProfiles = merlinProfiles.keepChromosomesRegionsOnly;
  const remaining = configAdvanced.remainingFeatures;

  return {
    sample_ids: splitIDs(parseSampleIDs(configPedigree)),
    father_ids: splitIDs(parseFatherIDs(configPedigree), true),
    mother_ids: splitIDs(parseMotherIDs(configPedigree), true),
    genders: splitIDs(parseGenders(configPedigree), true),
    dp_hard_limit_ids: splitIDs(parseDpHardLimitIDs(configPedigree)),
    af_hard_limit_ids: splitIDs(parseAfHardLimitIDs(configPedigree)),
    af_hard_limit: numberValue(configParameters.afHardLimit),
    dp_soft_limit_ids: splitIDs(parseDpSoftLimitIDs(configPedigree)),
    keep_informative_ids: splitIDs(parseKeepInformativeIDs(configPedigree)),
    keep_hetero_ids: splitIDs(parseKeepHeteroIDs(configPedigree)),
    regions: sampleDisease.regions.map(function(region) {
      return `${region.chr}:${region.chrStart}-${region.chrEnd}`;
    }),
    carrier_ids: splitIDs(parseCarrierIDs(configPedigree)),
    affected_ids: splitIDs(parseAffectedIDs(configPedigree)),
    nonaffected_ids: splitIDs(parseNonAffectedIDs(configPedigree)),
    info: buildInfo(sampleDisease),
    baf_ids: splitIDs(parseBafIDs(configPedigree)),
    window_size_voting: numberValue(merlinProfiles.windowSizeVoting),
    keep_chromosomes_only: keepProfiles.keepChromosomesOnly === true,
    keep_regions_only: keepProfiles.keepRegionsOnly === true,
    fam_id: configPedigree.famID,
    regions_flanking_size: numberValue(remaining.regionsFlankingSize),
    limit_baf_to_p: remaining.limitBafToP === true,
    limit_pm_to_p: remaining.limitPmToP === true,
    value_of_p: numberValue(remaining.valueOfP),
    self_contained: remaining.selfContained === true,
  };
}

export function form2SettingsYaml(configPedigree, configParameters, configAdvanced) {
  return stringify(
    form2Settings(configPedigree, configParameters, configAdvanced),
    { lineWidth: 0 },
  );
}
