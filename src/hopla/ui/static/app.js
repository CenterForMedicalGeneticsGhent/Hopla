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

function message(text, error = false) {
  const node = document.querySelector("#message");
  node.textContent = text;
  node.classList.toggle("error", error);
}

function newMember(role, index) {
  return {
    role,
    sample_id: role === "embryo" ? `embryo-${index + 1}` : `sibling-${index + 1}`,
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
        state.members[role] = newMember(role, 0);
        state.members[role].sample_id = placeholders[role];
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
}

const scalarFields = [
  "fam_id", "af_hard_limit", "window_size_voting", "info",
  "regions_flanking_size", "value_of_p",
];
const checkboxFields = [
  "keep_chromosomes_only", "keep_regions_only", "limit_pm_to_p",
  "limit_baf_to_p",
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

document.querySelectorAll("input, select, textarea").forEach((input) => {
  if (input.id !== "config-upload") input.addEventListener("input", schedulePreview);
});
fillFields();
renderMembers();
schedulePreview();
