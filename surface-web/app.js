const daemonBaseUrl =
  localStorage.getItem("glassdeck-daemon-url") || "http://127.0.0.1:7878";

const fallbackActions = [
  { id: "ping", label: "Tester la connexion", kind: "system" },
  { id: "status", label: "Lire l'état du daemon", kind: "system" },
  { id: "open-applications", label: "Applications", kind: "application" },
];

const state = {
  actions: fallbackActions,
  online: false,
  brightness: Number(localStorage.getItem("glassdeck-brightness") || "100"),
  volume: Number(localStorage.getItem("glassdeck-volume") || "70"),
};

const elements = {
  batteryDetail: document.querySelector("#battery-detail"),
  batteryExtra: document.querySelector("#battery-extra"),
  batteryStatus: document.querySelector("#battery-status"),
  brightnessSlider: document.querySelector("#brightness-slider"),
  brightnessValue: document.querySelector("#brightness-value"),
  clock: document.querySelector("#clock"),
  controlCenter: document.querySelector("#control-center"),
  controlCenterButton: document.querySelector("#control-center-button"),
  daemonLabel: document.querySelector("#daemon-label"),
  daemonState: document.querySelector("#daemon-state"),
  daemonUrl: document.querySelector("#daemon-url"),
  dimmer: document.querySelector("#screen-dimmer"),
  ipDetail: document.querySelector("#ip-detail"),
  machineIp: document.querySelector("#machine-ip"),
  refreshButton: document.querySelector("#refresh-button"),
  surfaceIp: document.querySelector("#surface-ip"),
  quitButton: document.querySelector("#quit-button"),
  volumeSlider: document.querySelector("#volume-slider"),
  volumeValue: document.querySelector("#volume-value"),
};

function daemonHostLabel() {
  try {
    const url = new URL(daemonBaseUrl);
    return url.hostname === "127.0.0.1" ? "Mac local" : url.hostname;
  } catch {
    return "Adresse inconnue";
  }
}

function updateClock() {
  const now = new Date();
  elements.clock.textContent = new Intl.DateTimeFormat("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(now);
}

function setControlCenterOpen(open) {
  elements.controlCenter.classList.toggle("is-open", open);
  elements.controlCenter.setAttribute("aria-hidden", String(!open));
  elements.controlCenterButton.setAttribute("aria-expanded", String(open));
}

function setConnectionState(online) {
  state.online = online;
  elements.daemonState.classList.toggle("is-online", online);
  elements.daemonState.classList.toggle("is-offline", !online);
  elements.daemonLabel.textContent = online ? "Connecté" : "Hors ligne";
}

function applyBrightness(value) {
  state.brightness = value;
  localStorage.setItem("glassdeck-brightness", String(value));
  elements.brightnessSlider.value = String(value);
  elements.brightnessValue.textContent = `${value}%`;

  const dimOpacity = Math.max(0, Math.min(0.55, (100 - value) / 100));
  elements.dimmer.style.opacity = String(dimOpacity);
}

function applyVolume(value) {
  state.volume = value;
  localStorage.setItem("glassdeck-volume", String(value));
  elements.volumeSlider.value = String(value);
  elements.volumeValue.textContent = `${value}%`;
}

function updateMachineInfo() {
  const host = daemonHostLabel();
  elements.machineIp.textContent = `IP ${host}`;
  elements.ipDetail.textContent = host;
  elements.daemonUrl.textContent = daemonBaseUrl;
}

function updateBatteryDisplay(battery) {
  const percent = Math.round(battery.level * 100);
  const charging = battery.charging ? "En charge" : "Sur batterie";
  elements.batteryStatus.textContent = `🔋 ${percent}%`;
  elements.batteryDetail.textContent = `${percent}%`;
  elements.batteryExtra.textContent = charging;
}

function updateSurfaceIp() {
  elements.surfaceIp.textContent = "192.168.10.57";
}

async function initBattery() {
  if (!("getBattery" in navigator)) {
    elements.batteryStatus.textContent = "Batterie --";
    elements.batteryDetail.textContent = "Batterie inconnue";
    elements.batteryExtra.textContent = "API batterie non disponible";
    return;
  }

  try {
    const battery = await navigator.getBattery();
    updateBatteryDisplay(battery);
    battery.addEventListener("levelchange", () => updateBatteryDisplay(battery));
    battery.addEventListener("chargingchange", () => updateBatteryDisplay(battery));
  } catch (error) {
    elements.batteryStatus.textContent = "Batterie --";
    elements.batteryDetail.textContent = "Batterie inconnue";
    elements.batteryExtra.textContent = error.message;
  }
}

async function refreshStatus() {
  try {
    const response = await fetch(`${daemonBaseUrl}/status`, {
      method: "GET",
      mode: "cors",
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const status = await response.json();
    state.actions = status.available_actions || fallbackActions;
    setConnectionState(true);
  } catch {
    state.actions = fallbackActions;
    setConnectionState(false);
  }
}

async function executeAction(actionId) {
  const action = state.actions.find((item) => item.id === actionId);
  if (!action) {
    return;
  }

  try {
    const response = await fetch(`${daemonBaseUrl}/command`, {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        request_id: crypto.randomUUID(),
        action_id: action.id,
        payload: action.payload || {},
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    setConnectionState(true);
  } catch {
    setConnectionState(false);
  }
}

elements.controlCenterButton.addEventListener("click", () => {
  setControlCenterOpen(!elements.controlCenter.classList.contains("is-open"));
});

elements.refreshButton.addEventListener("click", refreshStatus);

elements.brightnessSlider.addEventListener("input", (event) => {
  applyBrightness(Number(event.target.value));
});

elements.volumeSlider.addEventListener("input", (event) => {
  applyVolume(Number(event.target.value));
});

elements.quitButton.addEventListener("click", () => {
  window.close();
  setTimeout(() => {
    document.body.innerHTML =
      '<div style="display:flex;align-items:center;justify-content:center;height:100vh;flex-direction:column;gap:20px;text-align:center;"><h1>GlassDeck Fermé</h1><p>Vous pouvez maintenant éteindre la Surface.</p></div>';
  }, 300);
});

document.querySelectorAll("[data-action]").forEach((button) => {
  button.addEventListener("click", () => executeAction(button.dataset.action));
});

document.addEventListener("click", (event) => {
  if (
    !elements.controlCenter.contains(event.target) &&
    !elements.controlCenterButton.contains(event.target)
  ) {
    setControlCenterOpen(false);
  }
});

updateMachineInfo();
updateSurfaceIp();
updateClock();
applyBrightness(state.brightness);
applyVolume(state.volume);
initBattery();
refreshStatus();
setInterval(updateClock, 1000);
setInterval(refreshStatus, 5000);
