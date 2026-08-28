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
let previewTimer;
let analysisTimer;

function message(text, error = false) {
  const node = document.querySelector("#message");
  node.textContent = text;
  node.classList.toggle("error", error);
}

function newMember(role, index) {
  return {
    role,
    sample_id: role === "embryo" ? `embryo-${index + 1}` : `sibling-${index + 1}`,
    gender: "NA",
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
    ".gender": ["gender", "value"],
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
  card.querySelector(".remove").addEventListener("click", remove);
}

function renderMembers() {
  Object.entries(fixedGroups).forEach(([containerId, roles]) => {
    const container = document.querySelector(`#${containerId}`);
    container.replaceChildren();
    roles.forEach((role) => {
      const card = document.querySelector("#member-template").content.firstElementChild.cloneNode(true);
      bindMemberCard(card, state.members[role], () => {
        const gender = role.includes("father") ? "M" : "F";
        state.members[role] = newMember(role, 0);
        state.members[role].sample_id = placeholders[role];
        state.members[role].gender = gender;
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
}

const scalarFields = [
  "fam_id", "af_hard_limit", "window_size_voting", "disease", "inheritance",
  "sequencing_note", "regions_flanking_size", "value_of_p",
];
const checkboxFields = [
  "keep_chromosomes_only", "keep_regions_only", "limit_pm_to_p",
  "limit_baf_to_p", "self_contained",
];

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
    .split("\n").map((value) => value.trim()).filter(Boolean);
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
  state.siblings.push(newMember("sibling", state.siblings.length));
  renderMembers();
  schedulePreview();
});
document.querySelector("#add-embryo").addEventListener("click", () => {
  state.embryos.push(newMember("embryo", state.embryos.length));
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
    const imported = (await response.json()).form;
    Object.keys(state).forEach((key) => delete state[key]);
    Object.assign(state, imported);
    fillFields();
    renderMembers();
    await updatePreview();
    message(`Imported ${file.name}.`);
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
  document.querySelector("#run-analysis").disabled = false;
  document.querySelector("#vcf-upload").disabled = false;
}

async function pollAnalysis(identifier) {
  try {
    const response = await fetch(`/api/analyses/${identifier}`);
    if (!response.ok) throw new Error(await responseError(response));
    const result = await response.json();
    if (result.status === "completed") {
      analysisState("Analysis complete. Download the HTML report below.");
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
    analysisState(result.message || "Analysis is running.");
    analysisTimer = setTimeout(() => pollAnalysis(identifier), 1000);
  } catch (error) {
    analysisState(error.message, true);
    finishAnalysis();
  }
}

document.querySelector("#vcf-upload").addEventListener("change", (event) => {
  const file = event.target.files[0];
  analysisState(file ? `Selected ${file.name}.` : "Select a VCF to begin.");
});

document.querySelector("#run-analysis").addEventListener("click", async () => {
  const picker = document.querySelector("#vcf-upload");
  const button = document.querySelector("#run-analysis");
  const file = picker.files[0];
  if (!file) {
    analysisState("Choose a VCF before running the analysis.", true);
    return;
  }
  readFields();
  clearTimeout(analysisTimer);
  button.disabled = true;
  picker.disabled = true;
  document.querySelector("#report-download").hidden = true;
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
