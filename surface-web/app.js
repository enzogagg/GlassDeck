const daemonBaseUrl =
  localStorage.getItem("glassdeck-daemon-url") || "http://127.0.0.1:7878";

const fallbackActions = [
  {
    id: "ping",
    label: "Tester la connexion",
    kind: "system",
  },
  {
    id: "status",
    label: "Lire l'état du daemon",
    kind: "system",
  },
  {
    id: "open-url",
    label: "Ouvrir Apple",
    kind: "application",
    payload: { url: "https://www.apple.com" },
  },
  {
    id: "open-applications",
    label: "Applications",
    kind: "application",
  },
];

const iconByAction = {
  ping: "⌁",
  status: "◎",
  "open-url": "↗",
  "open-applications": "▦",
};

const state = {
  actions: fallbackActions,
  online: false,
};

const elements = {
  actionGrid: document.querySelector("#action-grid"),
  daemonState: document.querySelector("#daemon-state"),
  detailTitle: document.querySelector("#detail-title"),
  detailMessage: document.querySelector("#detail-message"),
  metricClients: document.querySelector("#metric-clients"),
  metricUptime: document.querySelector("#metric-uptime"),
  refreshButton: document.querySelector("#refresh-button"),
};

function formatKind(kind) {
  const labels = {
    system: "Système",
    application: "Application",
    script: "Script",
  };

  return labels[kind] || kind;
}

function formatUptime(seconds) {
  if (seconds < 60) {
    return `${seconds}s`;
  }

  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) {
    return `${minutes}m`;
  }

  return `${Math.floor(minutes / 60)}h`;
}

function setConnectionState(online) {
  state.online = online;
  elements.daemonState.textContent = online ? "Connecté" : "Hors ligne";
  elements.daemonState.classList.toggle("is-online", online);
  elements.daemonState.classList.toggle("is-offline", !online);
}

function setDetail(title, message) {
  elements.detailTitle.textContent = title;
  elements.detailMessage.textContent = message;
}

function renderActions() {
  elements.actionGrid.innerHTML = "";

  for (const action of state.actions) {
    const button = document.createElement("button");
    button.className = "action-card";
    button.type = "button";
    button.dataset.action = action.id;

    const icon = document.createElement("span");
    icon.className = "action-icon";
    icon.textContent = iconByAction[action.id] || "⌘";

    const title = document.createElement("p");
    title.className = "action-title";
    title.textContent = action.label;

    const kind = document.createElement("span");
    kind.className = "action-kind";
    kind.textContent = formatKind(action.kind);

    button.append(icon, title, kind);
    button.addEventListener("click", () => executeAction(action));
    elements.actionGrid.append(button);
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
    elements.metricClients.textContent = String(status.connected_clients ?? 0);
    elements.metricUptime.textContent = formatUptime(status.uptime_seconds ?? 0);
    setConnectionState(true);
    setDetail(status.daemon_name || "Mac connecté", "Actions synchronisées.");
    renderActions();
  } catch (error) {
    setConnectionState(false);
    setDetail("Mode local", `Daemon non joignable: ${error.message}`);
    state.actions = fallbackActions;
    renderActions();
  }
}

async function executeAction(action) {
  const payload = action.payload || {};

  try {
    setDetail(action.label, "Exécution en cours...");

    const response = await fetch(`${daemonBaseUrl}/command`, {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        request_id: crypto.randomUUID(),
        action_id: action.id,
        payload,
      }),
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const result = await response.json();
    setConnectionState(true);
    setDetail(action.label, result.message || "Action terminée.");
  } catch (error) {
    setConnectionState(false);
    setDetail(action.label, `Échec: ${error.message}`);
  }
}

elements.refreshButton.addEventListener("click", refreshStatus);

document.querySelectorAll(".dock-button").forEach((button) => {
  button.addEventListener("click", () => {
    const action = state.actions.find((item) => item.id === button.dataset.action);
    if (action) {
      executeAction(action);
    }
  });
});

renderActions();
refreshStatus();
setInterval(refreshStatus, 5000);
