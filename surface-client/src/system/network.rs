use super::command::command_output;

pub struct NetworkStatus {
    pub name: String,
    pub state: String,
}

pub fn read_network() -> NetworkStatus {
    if let Some(ssid) = current_wifi_ssid() {
        return NetworkStatus {
            name: ssid,
            state: "Connecté".to_string(),
        };
    }

    NetworkStatus {
        name: "Wi‑Fi".to_string(),
        state: wifi_radio_state(),
    }
}

pub fn read_ip_address() -> String {
    if let Some(ip) = read_active_wifi_ip() {
        return ip;
    }

    if let Some(ip) = read_active_global_ip() {
        return ip;
    }

    if let Ok(output) = command_output("ip", &["-4", "route", "get", "1.1.1.1"]) {
        let parts: Vec<&str> = output.split_whitespace().collect();
        if let Some(index) = parts.iter().position(|part| *part == "src") {
            if let Some(ip) = parts.get(index + 1) {
                return (*ip).to_string();
            }
        }
    }

    command_output("hostname", &["-I"])
        .ok()
        .and_then(|output| output.split_whitespace().next().map(ToOwned::to_owned))
        .unwrap_or_else(|| "Aucune IP".to_string())
}

fn current_wifi_ssid() -> Option<String> {
    let output = command_output("nmcli", &["-t", "-f", "ACTIVE,SSID", "dev", "wifi"]).ok()?;
    output.lines().find_map(|line| {
        line.strip_prefix("yes:")
            .map(str::trim)
            .filter(|ssid| !ssid.is_empty())
            .map(ToOwned::to_owned)
    })
}

fn wifi_radio_state() -> String {
    command_output("nmcli", &["radio", "wifi"])
        .ok()
        .map(|state| {
            if state.trim().eq_ignore_ascii_case("enabled") {
                "Non connecté"
            } else {
                "Désactivé"
            }
        })
        .unwrap_or("Indisponible")
        .to_string()
}

fn read_active_wifi_ip() -> Option<String> {
    read_active_global_ip_by(|interface| {
        interface.starts_with("wl") || interface.starts_with("wifi")
    })
}

fn read_active_global_ip() -> Option<String> {
    read_active_global_ip_by(|_| true)
}

fn read_active_global_ip_by(matches_interface: impl Fn(&str) -> bool) -> Option<String> {
    let output =
        command_output("ip", &["-o", "-4", "addr", "show", "scope", "global", "up"]).ok()?;

    output.lines().find_map(|line| {
        let mut parts = line.split_whitespace();
        parts.next()?;
        let interface = parts.next()?.trim_end_matches(':');
        if !matches_interface(interface) {
            return None;
        }

        parts
            .position(|part| part == "inet")
            .and_then(|_| parts.next())
            .and_then(|address| address.split('/').next())
            .map(ToOwned::to_owned)
    })
}
