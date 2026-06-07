use super::fs_util::{first_dir, read_trimmed};

pub struct BatteryStatus {
    pub percent: i32,
    pub state: String,
    pub charging: bool,
}

pub fn read_battery() -> BatteryStatus {
    let Some(battery_dir) = first_dir("/sys/class/power_supply", |path| {
        read_trimmed(path.join("type")).is_some_and(|kind| kind == "Battery")
    }) else {
        return BatteryStatus {
            percent: 0,
            state: "Batterie indisponible".to_string(),
            charging: false,
        };
    };

    let percent = read_trimmed(battery_dir.join("capacity"))
        .and_then(|value| value.parse::<i32>().ok())
        .unwrap_or(0)
        .clamp(0, 100);

    let status = read_trimmed(battery_dir.join("status")).unwrap_or_else(|| "Unknown".to_string());
    let charging = matches!(status.as_str(), "Charging" | "Full");
    let state = match status.as_str() {
        "Charging" => "En charge",
        "Discharging" => "Sur batterie",
        "Full" => "Charge complète",
        "Not charging" => "Branchée, sans charge",
        _ => "État inconnu",
    };

    BatteryStatus {
        percent,
        state: state.to_string(),
        charging,
    }
}
