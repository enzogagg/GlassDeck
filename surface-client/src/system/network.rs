use super::command::{command_output, command_success, run_command};
use std::process::Command;

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

    if command_success("ip", &["route", "get", "1.1.1.1"]) {
        return NetworkStatus {
            name: "Ethernet".to_string(),
            state: "Connecté".to_string(),
        };
    }

    NetworkStatus {
        name: "Hors ligne".to_string(),
        state: "Non connecté".to_string(),
    }
}

pub fn read_ip_address() -> String {
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

pub fn connect_wifi(ssid: &str, password: &str) -> Result<(), String> {
    let ssid = ssid.trim();
    if ssid.is_empty() {
        return Err("nom du réseau requis".to_string());
    }

    let mut command = Command::new("nmcli");
    command.args(["dev", "wifi", "connect", ssid]);
    if !password.trim().is_empty() {
        command.args(["password", password]);
    }

    run_command(command)
}

pub fn toggle_wifi() -> Result<String, String> {
    let radio = command_output("nmcli", &["radio", "wifi"]).map_err(|_| "nmcli indisponible")?;
    let enabled = radio.trim().eq_ignore_ascii_case("enabled");
    let target = if enabled { "off" } else { "on" };

    run_command({
        let mut command = Command::new("nmcli");
        command.args(["radio", "wifi", target]);
        command
    })?;

    Ok(if enabled {
        "Wi‑Fi désactivé".to_string()
    } else {
        "Wi‑Fi activé".to_string()
    })
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
