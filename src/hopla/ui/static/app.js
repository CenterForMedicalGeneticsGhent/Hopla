"use strict";

const state = JSON.parse(document.querySelector("#initial-state").textContent);
const fixedGroups = {
  grandparents: [
    "paternal_grandfather", "paternal_grandmother",
    "maternal_grandfather", "maternal_grandmother",
  ],
  parents: ["father", "mother"],
};
const labels = {
  paternal_grandfather: "Paternal grandfather",
  paternal_grandmother: "Paternal grandmother",
  maternal_grandfather: "Maternal grandfather",
  maternal_grandmother: "Maternal grandmother",
  father: "Father",
  mother: "Mother",
  sibling: "Sibling",
  embryo: "Embryo",
};
const placeholders = {
  paternal_grandfather: "U3",
  paternal_grandmother: "U4",
  maternal_grandfather: "U5",
  maternal_grandmother: "U6",
  father: "U1",
  mother: "U2",
};
// Merlin skips any chromosome whose pedigree scores above 24 bits, counted as
// 2 x non-founders - founders. Mirrors add_ghosts() in hopla/pedigree.py, which
// gives every half-orphan its own ghost founder.
const MERLIN_BIT_LIMIT = 24;
let overMemberLimit = false;
let previewTimer;
let analysisTimer;

function isActiveMember(role) {
  return state.members[role].sample_id !== placeholders[role];
}

function activeId(role) {
  return isActiveMember(role) ? state.members[role].sample_id : null;
}

function pedigreeMembers(extraChildren) {
  const father = activeId("father");
  const mother = activeId("mother");
  const paternalGrandfather = activeId("paternal_grandfather");
  const paternalGrandmother = activeId("paternal_grandmother");
  const maternalGrandfather = activeId("maternal_grandfather");
  const maternalGrandmother = activeId("maternal_grandmother");
  const members = [];
  if (paternalGrandfather) members.push({id: paternalGrandfather, father: null, mother: null});
  if (paternalGrandmother) members.push({id: paternalGrandmother, father: null, mother: null});
  if (maternalGrandfather) members.push({id: maternalGrandfather, father: null, mother: null});
  if (maternalGrandmother) members.push({id: maternalGrandmother, father: null, mother: null});
  if (father) members.push({id: father, father: paternalGrandfather, mother: paternalGrandmother});
  if (mother) members.push({id: mother, father: maternalGrandfather, mother: maternalGrandmother});
  const children = state.siblings.length + state.embryos.length + extraChildren;
  for (let index = 0; index < children; index += 1) {
    members.push({id: `child-${index}`, father, mother});
  }
  return members;
}

function addGhosts(members) {
  const used = new Set(members.map((member) => member.id));
  let counter = 0;
  const ghostId = () => {
    let identifier;
    do {
      counter += 1;
      identifier = `U${counter}`;
    } while (used.has(identifier));
    used.add(identifier);
    return identifier;
  };
  for (const member of [...members]) {
    const missingFather = member.father == null;
    const missingMother = member.mother == null;
    if (missingFather === missingMother) continue;
    const ghost = ghostId();
    if (missingFather) member.father = ghost;
    else member.mother = ghost;
    members.push({id: ghost, father: null, mother: null});
  }
  return members;
}

function merlinBitScore(extraChildren = 0) {
  const members = addGhosts(pedigreeMembers(extraChildren));
  const descendants = members.filter((member) => member.father || member.mother).length;
  return 2 * descendants - (members.length - descendants);
}

function showMemberLimit(text) {
  document.querySelector("#member-limit-text").textContent = text;
  document.querySelector("#member-limit").showModal();
}

function blockedByMemberLimit() {
  if (merlinBitScore(1) <= MERLIN_BIT_LIMIT) return false;
  const children = state.siblings.length + state.embryos.length;
  showMemberLimit(
    `This family already has ${children} children and scores ${merlinBitScore()} of ` +
    `Merlin's ${MERLIN_BIT_LIMIT} complexity bits. Adding another would make Merlin skip ` +
    "every autosome, leaving the report without haplotype panels, so this member was not " +
    "added. Remove a member, or run without Merlin haplotyping."
  );
  return true;
}

function warnIfOverMemberLimit() {
  const bits = merlinBitScore();
  const over = bits > MERLIN_BIT_LIMIT;
  if (over && !overMemberLimit) {
    const children = state.siblings.length + state.embryos.length;
    showMemberLimit(
      `This family has ${children} children and scores ${bits} of Merlin's ${MERLIN_BIT_LIMIT} ` +
      "complexity bits. Merlin will skip every autosome, so the report will have no haplotype " +
      "panels. Remove members to bring the family back within the limit."
    );
  }
  overMemberLimit = over;
}

function message(text, error = false) {
  const node = document.querySelector("#message");
  node.textContent = text;
  node.classList.toggle("error", error);
}

function usedSampleIds() {
  return new Set([
    ...Object.values(state.members).map((member) => member.sample_id),
    ...state.siblings.map((member) => member.sample_id),
    ...state.embryos.map((member) => member.sample_id),
  ]);
}

function nextSampleId(prefix) {
  const used = usedSampleIds();
  let n = 1;
  while (used.has(`${prefix}-${n}`)) n += 1;
  return `${prefix}-${n}`;
}

function newMember(role, sampleId) {
  return {
    role,
    sample_id: sampleId,
    sex: "NA",
    disease_status: "NA",
    hard_dp: role === "sibling",
    hard_af: role === "sibling",
    soft_dp: role === "embryo",
    informative: false,
    hetero: false,
    baf: role === "embryo",
  };
}

function bindMemberCard(card, member, remove) {
  card.querySelector("h3").textContent = labels[member.role];
  const fields = {
    ".sample-id": ["sample_id", "value"],
    ".sex": ["sex", "value"],
    ".disease-status": ["disease_status", "value"],
    ".hard-dp": ["hard_dp", "checked"],
    ".hard-af": ["hard_af", "checked"],
    ".soft-dp": ["soft_dp", "checked"],
    ".informative": ["informative", "checked"],
    ".hetero": ["hetero", "checked"],
    ".baf": ["baf", "checked"],
  };
  Object.entries(fields).forEach(([selector, [key, property]]) => {
    const input = card.querySelector(selector);
    input[property] = member[key];
    input.addEventListener("input", () => {
      member[key] = input[property];
      schedulePreview();
    });
  });
  card.querySelector(".sample-id").addEventListener("change", warnIfOverMemberLimit);
  card.querySelector(".remove").addEventListener("click", remove);
}

function renderMembers() {
  Object.entries(fixedGroups).forEach(([containerId, roles]) => {
    const container = document.querySelector(`#${containerId}`);
    container.replaceChildren();
    roles.forEach((role) => {
      const card = document.querySelector("#member-template").content.firstElementChild.cloneNode(true);
      bindMemberCard(card, state.members[role], () => {
        const sex = role.includes("father") ? "M" : "F";
        state.members[role] = newMember(role, placeholders[role]);
        state.members[role].sex = sex;
        renderMembers();
        schedulePreview();
      });
      container.append(card);
    });
  });
  ["siblings", "embryos"].forEach((collection) => {
    const container = document.querySelector(`#${collection}`);
    container.replaceChildren();
    state[collection].forEach((member, index) => {
      const card = document.querySelector("#member-template").content.firstElementChild.cloneNode(true);
      bindMemberCard(card, member, () => {
        state[collection].splice(index, 1);
        renderMembers();
        schedulePreview();
      });
      container.append(card);
    });
  });
  warnIfOverMemberLimit();
}

const scalarFields = [
  "fam_id", "af_hard_limit", "window_size_voting", "info",
  "regions_flanking_size", "value_of_p",
];
const checkboxFields = [
  "keep_chromosomes_only", "keep_regions_only", "limit_pm_to_p",
  "limit_baf_to_p",
];

function sanitizeRegion(value) {
  const text = value.replace(/[\s,\u00a0\u202f\uff0c\u066c]/g, "");
  if (!text.includes(":")) return value;
  const colon = text.indexOf(":");
  const chrom = text.slice(0, colon);
  const interval = text.slice(colon + 1);
  let name = /^chr/i.test(chrom) ? chrom.slice(3) : chrom;
  if (/^[xy]$/i.test(name)) name = name.toUpperCase();
  return `chr${name}:${interval}`;
}

function fillFields() {
  scalarFields.forEach((key) => { document.querySelector(`#${key}`).value = state[key]; });
  checkboxFields.forEach((key) => { document.querySelector(`#${key}`).checked = state[key]; });
  document.querySelector("#regions").value = state.regions.join("\n");
}

function readFields() {
  scalarFields.forEach((key) => {
    const input = document.querySelector(`#${key}`);
    state[key] = input.type === "number" ? Number(input.value) : input.value;
  });
  checkboxFields.forEach((key) => { state[key] = document.querySelector(`#${key}`).checked; });
  state.regions = document.querySelector("#regions").value
    .split("\n").map((value) => value.trim()).filter(Boolean).map(sanitizeRegion);
  document.querySelector("#regions").value = state.regions.join("\n");
}

async function api(path, payload) {
  const response = await fetch(path, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    const result = await response.json();
    throw new Error(result.error || "The server could not process this request.");
  }
  return response;
}

async function responseError(response) {
  try {
    const result = await response.json();
    return result.error || "The server could not process this request.";
  } catch {
    return "The server could not process this request.";
  }
}

async function updatePreview() {
  readFields();
  try {
    const response = await api("/api/preview", {form: state});
    const result = await response.json();
    document.querySelector("#yaml-preview").textContent = result.yaml;
    message("Configuration is valid.");
  } catch (error) {
    document.querySelector("#yaml-preview").textContent = "";
    message(error.message, true);
  }
}

function schedulePreview() {
  clearTimeout(previewTimer);
  previewTimer = setTimeout(updatePreview, 250);
}

document.querySelectorAll("[data-tab]").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll("[data-tab], .panel").forEach((node) => node.classList.remove("active"));
    button.classList.add("active");
    document.querySelector(`#${button.dataset.tab}`).classList.add("active");
    if (button.dataset.tab === "config") updatePreview();
  });
});

document.querySelector("#add-sibling").addEventListener("click", () => {
  if (blockedByMemberLimit()) return;
  state.siblings.push(newMember("sibling", nextSampleId("sibling")));
  renderMembers();
  schedulePreview();
});
document.querySelector("#add-embryo").addEventListener("click", () => {
  if (blockedByMemberLimit()) return;
  state.embryos.push(newMember("embryo", nextSampleId("embryo")));
  renderMembers();
  schedulePreview();
});

document.querySelector("#config-upload").addEventListener("change", async (event) => {
  const file = event.target.files[0];
  if (!file) return;
  if (file.size > 1024 * 1024) {
    message("Configuration files must be 1 MB or smaller.", true);
    return;
  }
  try {
    const response = await api("/api/import", {name: file.name, content: await file.text()});
    const result = await response.json();
    const imported = result.form;
    Object.keys(state).forEach((key) => delete state[key]);
    Object.assign(state, imported);
    fillFields();
    renderMembers();
    await updatePreview();
    const ignored = result.warnings || [];
    if (ignored.length) {
      message(`Imported ${file.name}. Ignored unsupported setting(s): ${ignored.join(", ")}.`);
    } else {
      message(`Imported ${file.name}.`);
    }
  } catch (error) {
    message(error.message, true);
  } finally {
    event.target.value = "";
  }
});

document.querySelector("#download").addEventListener("click", async () => {
  readFields();
  try {
    const response = await api("/api/download", {form: state});
    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${state.fam_id || "hopla"}.yaml`;
    link.click();
    URL.revokeObjectURL(url);
    message("Downloaded validated YAML.");
  } catch (error) {
    message(error.message, true);
  }
});

function analysisState(text, error = false) {
  const node = document.querySelector("#analysis-status");
  node.textContent = text;
  node.classList.toggle("error", error);
}

function finishAnalysis() {
  clearTimeout(analysisTimer);
  document.querySelector("#analysis-progress").hidden = true;
  document.querySelector("#run-analysis").disabled = false;
  document.querySelector("#vcf-upload").disabled = false;
}

function renderLog(entries) {
  const list = document.querySelector("#analysis-log");
  list.replaceChildren(...entries.map((entry) => {
    const item = document.createElement("li");
    const seconds = document.createElement("span");
    seconds.className = "log-time";
    seconds.textContent = `${entry.seconds.toFixed(1)} s`;
    item.append(seconds, entry.message);
    return item;
  }));
  list.hidden = entries.length === 0;
  list.scrollTop = list.scrollHeight;
}

async function pollAnalysis(identifier) {
  try {
    const response = await fetch(`/api/analyses/${identifier}`);
    if (!response.ok) throw new Error(await responseError(response));
    const result = await response.json();
    renderLog(result.log || []);
    if (result.status === "completed") {
      analysisState(`Analysis complete in ${result.elapsed} s. Download the report below.`);
      const link = document.querySelector("#report-download");
      link.href = result.report_url;
      link.hidden = false;
      finishAnalysis();
      return;
    }
    if (result.status === "failed") {
      analysisState(result.error || "Analysis failed.", true);
      finishAnalysis();
      return;
    }
    analysisState(`${result.message || "Analysis is running"} (${result.elapsed} s)`);
    analysisTimer = setTimeout(() => pollAnalysis(identifier), 1000);
  } catch (error) {
    analysisState(error.message, true);
    finishAnalysis();
  }
}

function isVcfName(name) {
  const lower = name.toLowerCase();
  return lower.endsWith(".vcf") || lower.endsWith(".vcf.gz") || lower.endsWith(".vcf.bgz");
}

document.querySelector("#vcf-upload")?.addEventListener("change", (event) => {
  const file = event.target.files[0];
  if (!file) {
    analysisState("Select a VCF to begin.");
    return;
  }
  if (!isVcfName(file.name)) {
    analysisState("Choose a .vcf, .vcf.gz, or .vcf.bgz file.", true);
    return;
  }
  analysisState(`Selected ${file.name}.`);
});

document.querySelector("#run-analysis")?.addEventListener("click", async () => {
  const picker = document.querySelector("#vcf-upload");
  const button = document.querySelector("#run-analysis");
  const file = picker.files[0];
  if (!file) {
    analysisState("Choose a VCF before running the analysis.", true);
    return;
  }
  if (!isVcfName(file.name)) {
    analysisState("Choose a .vcf, .vcf.gz, or .vcf.bgz file.", true);
    return;
  }
  readFields();
  clearTimeout(analysisTimer);
  button.disabled = true;
  picker.disabled = true;
  document.querySelector("#report-download").hidden = true;
  document.querySelector("#analysis-progress").hidden = false;
  renderLog([]);
  try {
    analysisState("Validating configuration.");
    const created = await api("/api/analyses", {form: state, vcf_name: file.name});
    const job = await created.json();
    analysisState(`Uploading ${file.name}.`);
    const compressed = file.name.toLowerCase().endsWith(".gz")
      || file.name.toLowerCase().endsWith(".bgz");
    const uploaded = await fetch(
      `/api/analyses/${job.id}/vcf?compressed=${compressed}`,
      {method: "PUT", headers: {"Content-Type": "application/octet-stream"}, body: file},
    );
    if (!uploaded.ok) throw new Error(await responseError(uploaded));
    analysisState("Analysis is starting.");
    await pollAnalysis(job.id);
  } catch (error) {
    analysisState(error.message, true);
    finishAnalysis();
  }
});

document.querySelectorAll("input, select, textarea").forEach((input) => {
  if (input.type !== "file") input.addEventListener("input", schedulePreview);
});
fillFields();
renderMembers();
schedulePreview();
