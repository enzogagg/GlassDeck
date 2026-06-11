const defaultDaemonBaseUrl = "http://127.0.0.1:7878";
const storedDaemonBaseUrl = localStorage.getItem("glassdeck-daemon-url");
let daemonBaseUrl = storedDaemonBaseUrl || defaultDaemonBaseUrl;

const fallbackActions = [
  { id: "ping", label: "Tester la connexion", kind: "system" },
  { id: "status", label: "Lire l'état du daemon", kind: "system" },
  { id: "open-applications", label: "Applications", kind: "application" },
];

const state = {
  actions: fallbackActions,
  battery: null,
  controlTimers: new Map(),
  online: false,
  autoDaemonUrl: !storedDaemonBaseUrl,
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
    if (url.hostname === "127.0.0.1") {
      return "Mac local";
    }
    return url.hostname;
  } catch {
    return "Adresse inconnue";
  }
}

function setDaemonBaseUrl(baseUrl, { persist = false } = {}) {
  if (!baseUrl || baseUrl === daemonBaseUrl) {
    return false;
  }

  daemonBaseUrl = baseUrl;
  if (persist) {
    localStorage.setItem("glassdeck-daemon-url", baseUrl);
    state.autoDaemonUrl = false;
  }
  updateMachineInfo();
  return true;
}

function updateClock() {
  const now = new Date();
  elements.clock.textContent = new Intl.DateTimeFormat("fr-FR", {
    hour: "2-digit",
    minute: "2-digit",
    timeZone: "Europe/Paris",
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
  elements.dimmer.style.opacity = "0";
}

function syncBrightnessSnapshot(snapshot = {}) {
  if (!Number.isFinite(snapshot.percent)) {
    return;
  }

  applyBrightness(snapshot.percent);
}

function applyVolume(value) {
  state.volume = value;
  localStorage.setItem("glassdeck-volume", String(value));
  elements.volumeSlider.value = String(value);
  elements.volumeValue.textContent = `${value}%`;
}

function updateControls(controls = {}) {
  const brightness = controls.brightness || {};
  const volume = controls.volume || {};

  elements.brightnessSlider.disabled = !brightness.available;
  if (!brightness.available) {
    elements.brightnessValue.textContent = "Indispo";
  }

  elements.volumeSlider.disabled = !volume.available;
  if (!volume.available) {
    elements.volumeValue.textContent = "Indispo";
  }
}

function queueSurfaceControl(control, value) {
  clearTimeout(state.controlTimers.get(control));
  state.controlTimers.set(
    control,
    setTimeout(() => {
      sendSurfaceControl(control, value);
    }, 120),
  );
}

async function sendSurfaceControl(control, value) {
  try {
    const response = await fetch("/surface-control", {
      body: JSON.stringify({ control, value }),
      cache: "no-store",
      headers: {
        "Content-Type": "application/json",
      },
      method: "POST",
    });

    const result = await response.json();
    if (!response.ok || !result.ok) {
      throw new Error(result.error || `HTTP ${response.status}`);
    }
  } catch (error) {
    if (control === "brightness") {
      elements.brightnessValue.textContent = "Erreur";
    }
    if (control === "volume") {
      elements.volumeValue.textContent = "Indispo";
    }
    console.error(`GlassDeck ${control}`, error);
  }
}

function updateMachineInfo() {
  const host = daemonHostLabel();
  const isBluetoothTarget = state.autoDaemonUrl && daemonBaseUrl !== defaultDaemonBaseUrl;
  elements.machineIp.textContent = `${isBluetoothTarget ? "BT" : "IP"} ${host}`;
  elements.ipDetail.textContent = host;
  elements.daemonUrl.textContent = daemonBaseUrl;
}

function updateBatteryDisplay(snapshot) {
  const percent = snapshot.percent;
  const charging = snapshot.charging ? "En charge" : "Sur batterie";
  elements.batteryStatus.textContent = `${snapshot.charging ? "⚡" : "🔋"} ${percent}%`;
  elements.batteryDetail.textContent = `${percent}%`;
  elements.batteryExtra.textContent = charging;
}

function updateSurfaceIp(addresses = []) {
  elements.surfaceIp.textContent = addresses[0] || "IP indisponible";
}

function syncBluetoothDaemon(bluetooth = {}) {
  if (!bluetooth.recommended_url || (!state.autoDaemonUrl && state.online)) {
    return false;
  }

  return setDaemonBaseUrl(bluetooth.recommended_url);
}

function browserBatterySnapshot(battery) {
  return {
    percent: Math.round(battery.level * 100),
    charging: battery.charging,
  };
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
    state.battery = battery;
    updateBatteryDisplay(browserBatterySnapshot(battery));
    battery.addEventListener("levelchange", () => updateBatteryDisplay(browserBatterySnapshot(battery)));
    battery.addEventListener("chargingchange", () => updateBatteryDisplay(browserBatterySnapshot(battery)));
  } catch (error) {
    elements.batteryStatus.textContent = "Batterie --";
    elements.batteryDetail.textContent = "Batterie inconnue";
    elements.batteryExtra.textContent = error.message;
  }
}

async function refreshSurfaceStatus() {
  try {
    const response = await fetch("/surface-status", {
      cache: "no-store",
      method: "GET",
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const status = await response.json();
    updateSurfaceIp(status.addresses || []);
    updateControls(status.controls || {});
    syncBrightnessSnapshot(status.controls?.brightness);
    const daemonChanged = syncBluetoothDaemon(status.bluetooth);
    if (daemonChanged) {
      refreshStatus();
    }

    if (status.battery && Number.isFinite(status.battery.percent)) {
      updateBatteryDisplay(status.battery);
      return;
    }
  } catch {
    updateSurfaceIp([]);
  }

  if (state.battery) {
    updateBatteryDisplay(browserBatterySnapshot(state.battery));
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
  const value = Number(event.target.value);
  applyBrightness(value);
  queueSurfaceControl("brightness", value);
});

elements.volumeSlider.addEventListener("input", (event) => {
  const value = Number(event.target.value);
  applyVolume(value);
  queueSurfaceControl("volume", value);
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
updateClock();
applyBrightness(state.brightness);
applyVolume(state.volume);
initBattery();
refreshSurfaceStatus();
refreshStatus();
setInterval(updateClock, 1000);
setInterval(refreshSurfaceStatus, 1000);
setInterval(refreshStatus, 5000);
