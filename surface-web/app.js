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
  bluetooth: null,
  selectedBluetoothAddress: null,
  controlTimers: new Map(),
  reconnecting: false,
  reconnectAttempts: 0,
  online: false,
  autoDaemonUrl: !storedDaemonBaseUrl,
  brightness: Number(localStorage.getItem("glassdeck-brightness") || "100"),
  volume: Number(localStorage.getItem("glassdeck-volume") || "70"),
  dashboard: null,
  metrics: null,
};

const elements = {
  batteryDetail: document.querySelector("#battery-detail"),
  batteryExtra: document.querySelector("#battery-extra"),
  batteryStatus: document.querySelector("#battery-status"),
  bluetoothDevices: document.querySelector("#bluetooth-devices"),
  bluetoothForgetButton: document.querySelector("#bluetooth-forget-button"),
  bluetoothLabel: document.querySelector("#bluetooth-label"),
  bluetoothScanButton: document.querySelector("#bluetooth-scan-button"),
  bluetoothStatus: document.querySelector("#bluetooth-status"),
  brightnessSlider: document.querySelector("#brightness-slider"),
  brightnessValue: document.querySelector("#brightness-value"),
  clock: document.querySelector("#clock"),
  controlCenter: document.querySelector("#control-center"),
  controlCenterButton: document.querySelector("#control-center-button"),
  controlSummary: document.querySelector("#control-summary"),
  actionDock: document.querySelector(".action-dock"),
  dashboardGrid: document.querySelector("#dashboard-grid"),
  daemonLabel: document.querySelector("#daemon-label"),
  daemonState: document.querySelector("#daemon-state"),
  daemonUrl: document.querySelector("#daemon-url"),
  dimmer: document.querySelector("#screen-dimmer"),
  dockRefreshButton: document.querySelector("#dock-refresh-button"),
  cpuDetail: document.querySelector("#cpu-detail"),
  homeCpu: document.querySelector("#home-cpu"),
  homeDaemonPill: document.querySelector("#home-daemon-pill"),
  homeMacSubtitle: document.querySelector("#home-mac-subtitle"),
  homeMemory: document.querySelector("#home-memory"),
  homeTemperature: document.querySelector("#home-temperature"),
  macMetrics: document.querySelector("#mac-metrics"),
  memoryDetail: document.querySelector("#memory-detail"),
  ipDetail: document.querySelector("#ip-detail"),
  installStatus: document.querySelector("#install-status"),
  machineIp: document.querySelector("#machine-ip"),
  macFoundStatus: document.querySelector("#mac-found-status"),
  refreshButton: document.querySelector("#refresh-button"),
  surfaceIp: document.querySelector("#surface-ip"),
  temperatureDetail: document.querySelector("#temperature-detail"),
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

function formatMemoryPair(usedBytes, totalBytes) {
  if (!Number.isFinite(usedBytes) || !Number.isFinite(totalBytes) || totalBytes <= 0) {
    return "--";
  }

  const totalGb = totalBytes / 1024 / 1024 / 1024;
  const usedGb = usedBytes / 1024 / 1024 / 1024;
  return `${usedGb.toFixed(1)}/${Math.round(totalGb)} GB`;
}

function formatPercent(value) {
  return Number.isFinite(value) ? `${Math.round(value)}%` : "--%";
}

function formatTemperature(value) {
  return Number.isFinite(value) && value > 0 ? `${Math.round(value)}°C` : "--°";
}

function readMetric(metrics, camelKey, snakeKey) {
  return metrics?.[camelKey] ?? metrics?.[snakeKey] ?? null;
}

function readDashboardValue(entity) {
  if (entity === "mac.daemon") {
    return state.online ? "Connecté" : "Hors ligne";
  }
  if (entity === "mac.cpu_percent") {
    const value = readMetric(state.metrics, "cpuPercent", "cpu_percent");
    return Number.isFinite(value) ? formatPercent(value) : "--%";
  }
  if (entity === "mac.memory_percent") {
    const value = readMetric(state.metrics, "memoryPercent", "memory_percent");
    return Number.isFinite(value) ? formatPercent(value) : "--%";
  }
  if (entity === "mac.temperature_celsius") {
    const value = readMetric(state.metrics, "temperatureCelsius", "temperature_celsius");
    return Number.isFinite(value) && value > 0 ? formatTemperature(value) : "--°";
  }
  return "--";
}

function normalizeGridValue(card, key, fallback) {
  const value = Number(card?.[key]);
  return Number.isFinite(value) ? Math.max(0, Math.round(value)) : fallback;
}

function renderDashboard(dashboard = state.dashboard) {
  if (!elements.dashboardGrid || !dashboard) {
    return;
  }

  state.dashboard = dashboard;
  renderDock(dashboard);
  const grid = dashboard.grid || {};
  const columns = Number(grid.columns) || 12;
  const rowHeight = Number(grid.rowHeight ?? grid.row_height) || 64;
  const gap = Number(grid.gap) || 12;

  elements.dashboardGrid.style.setProperty("--dashboard-columns", String(columns));
  elements.dashboardGrid.style.setProperty("--dashboard-row-height", `${rowHeight}px`);
  elements.dashboardGrid.style.setProperty("--dashboard-gap", `${gap}px`);
  elements.dashboardGrid.innerHTML = "";

  for (const card of dashboard.cards || []) {
    const item = document.createElement(card.type === "button" ? "button" : "article");
    const eyebrow = document.createElement("span");
    const title = document.createElement("strong");
    const value = document.createElement("b");
    const subtitle = document.createElement("small");

    item.className = `dashboard-card dashboard-card-${card.type || "metric"}`;
    const x = normalizeGridValue(card, "x", 0);
    const y = normalizeGridValue(card, "y", 0);
    const width = Math.max(1, normalizeGridValue(card, "w", 3));
    const height = Math.max(1, normalizeGridValue(card, "h", 2));

    item.style.gridColumn = `${x + 1} / span ${width}`;
    item.style.gridRow = `${y + 1} / span ${height}`;

    if (card.type === "button") {
      item.type = "button";
      item.dataset.dashboardAction = card.action || "";
      value.textContent = "Action";
    } else {
      value.textContent = readDashboardValue(card.entity);
    }

    eyebrow.className = "dashboard-card-eyebrow";
    eyebrow.textContent = card.type === "button" ? "Commande" : "Entité";
    title.textContent = card.title || "Carte";
    value.className = "dashboard-card-value";
    subtitle.textContent = card.subtitle || card.entity || card.action || "";

    item.append(eyebrow, title, value, subtitle);
    elements.dashboardGrid.append(item);
  }
}

function dockIconClass(action) {
  if (action === "open-applications") {
    return "dock-icon-apps";
  }
  if (action === "status") {
    return "dock-icon-sync";
  }
  return "dock-icon-ping";
}

function renderDock(dashboard = state.dashboard) {
  if (!elements.actionDock || !dashboard) {
    return;
  }

  const dockActions = dashboard.dockActions || dashboard.dock_actions || [];
  if (dockActions.length === 0) {
    return;
  }

  elements.actionDock.innerHTML = "";
  for (const dockAction of dockActions) {
    const button = document.createElement("button");
    const icon = document.createElement("span");
    const label = document.createElement("small");

    button.className = "dock-button";
    button.type = "button";
    button.dataset.action = dockAction.action;
    button.setAttribute("aria-label", dockAction.title || dockAction.action);
    icon.className = `dock-icon ${dockIconClass(dockAction.action)}`;
    icon.setAttribute("aria-hidden", "true");
    label.textContent = dockAction.title || dockAction.action;
    button.append(icon, label);
    elements.actionDock.append(button);
  }
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
  elements.controlSummary.textContent = online ? `Mac connecté · ${daemonHostLabel()}` : "Mac hors ligne";
  elements.homeDaemonPill?.classList.toggle("is-online", online);
  if (elements.homeDaemonPill) {
    elements.homeDaemonPill.textContent = online ? "Connecté" : "Hors ligne";
  }
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

function updateInstallDisplay(install = {}) {
  elements.installStatus.textContent = install.ok ? "OK" : "Incomplet";
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
  if (elements.machineIp) {
    elements.machineIp.textContent = `${isBluetoothTarget ? "BT" : "IP"} ${host}`;
  }
  elements.ipDetail.textContent = host;
  elements.daemonUrl.textContent = `${isBluetoothTarget ? "Bluetooth/PAN" : "Réseau"} · ${daemonBaseUrl}`;
  if (elements.homeMacSubtitle) {
    elements.homeMacSubtitle.textContent = `${isBluetoothTarget ? "Bluetooth/PAN" : "Réseau"} · ${host}`;
  }
}

function updateMacMetrics(metrics = null) {
  state.metrics = metrics;

  const cpuPercent = readMetric(metrics, "cpuPercent", "cpu_percent");
  const memoryPercent = readMetric(metrics, "memoryPercent", "memory_percent");
  const rawTemperature = readMetric(metrics, "temperatureCelsius", "temperature_celsius");
  const temperature = Number.isFinite(rawTemperature) && rawTemperature > 0 ? rawTemperature : null;
  const temperatureSource = readMetric(metrics, "temperatureSource", "temperature_source");
  const memoryUsedBytes = readMetric(metrics, "memoryUsedBytes", "memory_used_bytes");
  const memoryTotalBytes = readMetric(metrics, "memoryTotalBytes", "memory_total_bytes");

  const cpuLabel = Number.isFinite(cpuPercent) ? formatPercent(cpuPercent) : "--";
  const memoryLabel = Number.isFinite(memoryPercent) ? formatPercent(memoryPercent) : "--";
  const temperatureLabel = Number.isFinite(temperature) ? formatTemperature(temperature) : "--";
  const temperatureDetail = Number.isFinite(temperature)
    ? formatTemperature(temperature)
    : temperatureSource
      ? "Indispo"
      : "--°C";

  elements.macMetrics.textContent = `CPU ${cpuLabel} · RAM ${memoryLabel} · Temp ${temperatureLabel}`;
  if (elements.homeCpu) {
    elements.homeCpu.textContent = cpuLabel;
  }
  if (elements.homeMemory) {
    elements.homeMemory.textContent =
      Number.isFinite(memoryUsedBytes) && Number.isFinite(memoryTotalBytes)
        ? formatMemoryPair(memoryUsedBytes, memoryTotalBytes)
        : memoryLabel;
  }
  if (elements.homeTemperature) {
    elements.homeTemperature.textContent = temperatureLabel;
  }
  elements.cpuDetail.textContent = Number.isFinite(cpuPercent) ? formatPercent(cpuPercent) : "--%";
  elements.memoryDetail.textContent =
    Number.isFinite(memoryUsedBytes) && Number.isFinite(memoryTotalBytes)
      ? formatMemoryPair(memoryUsedBytes, memoryTotalBytes)
      : Number.isFinite(memoryPercent)
        ? formatPercent(memoryPercent)
        : "--";
  elements.temperatureDetail.textContent = Number.isFinite(temperature)
    ? formatTemperature(temperature)
    : temperatureDetail;
  renderDashboard();
}

function updateBatteryDisplay(snapshot) {
  const percent = snapshot.percent;
  const charging = snapshot.charging ? "En charge" : "Sur batterie";
  elements.batteryStatus.textContent = `${snapshot.charging ? "Charge" : "Batterie"} ${percent}%`;
  elements.batteryDetail.textContent = `${percent}%`;
  elements.batteryExtra.textContent = charging;
}

function updateSurfaceIp(addresses = []) {
  elements.surfaceIp.textContent = addresses[0] || "IP indisponible";
}

function deviceStatusLabel(device) {
  if (device.connected) {
    return "Connecté";
  }
  if (device.trusted) {
    return "Validé";
  }
  if (device.paired) {
    return "Appairé";
  }
  return "Nouveau";
}

function updateBluetoothDisplay(bluetooth = {}) {
  state.bluetooth = bluetooth;
  const devices = bluetooth.devices || [];
  const connected = devices.find((device) => device.connected);
  const preferred = connected || devices.find((device) => device.mac_candidate) || devices[0];
  state.selectedBluetoothAddress = preferred?.address || null;
  elements.bluetoothForgetButton.disabled = !state.selectedBluetoothAddress;

  if (!bluetooth.ready) {
    elements.bluetoothLabel.textContent = "Indisponible";
    elements.bluetoothStatus.textContent = "Indispo";
    elements.macFoundStatus.textContent = "Non";
    elements.bluetoothDevices.innerHTML = "";
    return;
  }

  elements.bluetoothStatus.textContent = connected ? "Connecté" : preferred?.trusted ? "Validé" : "Prêt";
  elements.macFoundStatus.textContent = bluetooth.daemon_reachable || bluetooth.recommended_url ? "Oui" : "Non";
  elements.bluetoothLabel.textContent = connected
    ? connected.name || connected.address
    : preferred
      ? "Mac détecté"
      : "Prêt";

  elements.bluetoothDevices.innerHTML = "";

  const preferredDevices = devices.filter((device) => device.mac_candidate || device.paired || device.trusted || device.connected);
  const visibleDevices = (preferredDevices.length > 0 ? preferredDevices : devices).slice(0, 4);
  if (visibleDevices.length === 0) {
    const empty = document.createElement("small");
    empty.textContent = "Aucun Mac détecté";
    elements.bluetoothDevices.append(empty);
    return;
  }

  for (const device of visibleDevices) {
    const button = document.createElement("button");
    const name = document.createElement("span");
    const status = document.createElement("small");

    button.className = "device-button";
    button.type = "button";
    button.dataset.bluetoothAddress = device.address;
    button.disabled = device.connected;
    button.classList.toggle("is-selected", device.address === state.selectedBluetoothAddress);
    name.textContent = device.name || device.address;
    status.textContent = deviceStatusLabel(device);
    button.append(name, status);
    elements.bluetoothDevices.append(button);
  }
}

function syncBluetoothDaemon(bluetooth = {}) {
  if (!bluetooth.recommended_url) {
    return false;
  }

  if (!state.autoDaemonUrl && !state.online) {
    state.autoDaemonUrl = true;
  }

  if (!state.autoDaemonUrl && state.online) {
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
    elements.batteryStatus.textContent = "Batterie --%";
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
    elements.batteryStatus.textContent = "Batterie --%";
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
    updateInstallDisplay(status.install || {});
    updateBluetoothDisplay(status.bluetooth || {});
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
    updateInstallDisplay({});
    updateBluetoothDisplay({});
  }

  if (state.battery) {
    updateBatteryDisplay(browserBatterySnapshot(state.battery));
  }
}

async function autoConnectMac() {
  if (state.online || state.reconnecting) {
    return;
  }

  state.reconnecting = true;
  state.reconnectAttempts += 1;
  elements.daemonLabel.textContent = "Recherche...";
  elements.controlSummary.textContent = `Recherche Mac · essai ${state.reconnectAttempts}`;

  try {
    const response = await fetch("/mac-status?force=1", {
      cache: "no-store",
      method: "GET",
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const result = await response.json();
    updateBluetoothDisplay(result.bluetooth || {});

    if (result.url) {
      setDaemonBaseUrl(result.url);
    }

    if (result.ok && result.status) {
      state.actions = result.status.available_actions || fallbackActions;
      updateMacMetrics(result.status.metrics || null);
      setConnectionState(true);
      refreshDashboard();
      return;
    }

    await refreshStatus();
  } catch (error) {
    setConnectionState(false);
    console.error("GlassDeck auto-connect", error);
  } finally {
    state.reconnecting = false;
  }
}

async function refreshDashboard() {
  try {
    const response = await fetch(`/dashboard${state.online ? "" : "?force=1"}`, {
      cache: "no-store",
      method: "GET",
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const result = await response.json();
    if (result.dashboard) {
      renderDashboard(result.dashboard);
    }
  } catch (error) {
    console.error("GlassDeck dashboard", error);
  }
}

async function sendBluetoothControl(action, payload = {}) {
  elements.bluetoothScanButton.disabled = true;
  try {
    const response = await fetch("/bluetooth-control", {
      body: JSON.stringify({ action, ...payload }),
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

    if (result.bluetooth) {
      updateBluetoothDisplay(result.bluetooth);
      const daemonChanged = syncBluetoothDaemon(result.bluetooth);
      if (daemonChanged) {
        refreshStatus();
      }
    } else if (result.devices) {
      updateBluetoothDisplay({ ready: true, devices: result.devices });
    }

    return result;
  } catch (error) {
    elements.bluetoothLabel.textContent = "Erreur";
    console.error("GlassDeck Bluetooth", error);
    return null;
  } finally {
    elements.bluetoothScanButton.disabled = false;
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
    updateMacMetrics(status.metrics || null);
    setConnectionState(true);
    renderDashboard();
  } catch {
    await refreshStatusThroughBridge();
  }
}

async function refreshStatusThroughBridge() {
  try {
    const response = await fetch("/mac-status", {
      cache: "no-store",
      method: "GET",
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const result = await response.json();
    if (!result.ok || !result.status) {
      throw new Error("Mac indisponible");
    }

    setDaemonBaseUrl(result.url);
    updateBluetoothDisplay(result.bluetooth || {});
    state.actions = result.status.available_actions || fallbackActions;
    updateMacMetrics(result.status.metrics || null);
    setConnectionState(true);
    renderDashboard();
  } catch {
    state.actions = fallbackActions;
    updateMacMetrics(null);
    setConnectionState(false);
    renderDashboard();
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
elements.dockRefreshButton.addEventListener("click", () => {
  refreshSurfaceStatus();
  refreshStatus();
});

elements.bluetoothScanButton.addEventListener("click", () => {
  sendBluetoothControl("scan");
});

elements.bluetoothForgetButton.addEventListener("click", () => {
  if (!state.selectedBluetoothAddress) {
    return;
  }

  sendBluetoothControl("forget", { address: state.selectedBluetoothAddress });
});

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
  if (button.closest(".action-dock")) {
    return;
  }
  button.addEventListener("click", () => executeAction(button.dataset.action));
});

elements.actionDock?.addEventListener("click", (event) => {
  const button = event.target.closest("[data-action]");
  if (button?.dataset.action) {
    executeAction(button.dataset.action);
  }
});

elements.bluetoothDevices.addEventListener("click", (event) => {
  const button = event.target.closest("[data-bluetooth-address]");
  if (!button) {
    return;
  }

  sendBluetoothControl("connect", { address: button.dataset.bluetoothAddress });
});

elements.dashboardGrid?.addEventListener("click", (event) => {
  const button = event.target.closest("[data-dashboard-action]");
  const actionId = button?.dataset.dashboardAction;
  if (actionId) {
    executeAction(actionId);
  }
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
updateMacMetrics(null);
initBattery();
sendBluetoothControl("prepare");
refreshSurfaceStatus();
refreshStatus();
refreshDashboard();
autoConnectMac();
setInterval(updateClock, 1000);
setInterval(refreshSurfaceStatus, 1000);
setInterval(refreshStatus, 1000);
setInterval(refreshDashboard, 5000);
setInterval(autoConnectMac, 3500);
