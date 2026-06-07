use super::command::run_command;
use super::fs_util::{first_dir, read_trimmed};
use std::fs;
use std::path::PathBuf;
use std::process::Command;

pub fn read_percent() -> Option<f32> {
    let backlight_dir = first_dir("/sys/class/backlight", |_| true)?;
    let brightness = read_trimmed(backlight_dir.join("brightness"))?
        .parse::<f32>()
        .ok()?;
    let max = read_trimmed(backlight_dir.join("max_brightness"))?
        .parse::<f32>()
        .ok()?;

    if max <= 0.0 {
        return None;
    }

    Some(((brightness / max) * 100.0).clamp(1.0, 100.0))
}

pub fn set_percent(percent: f32) -> Result<(), String> {
    let percent = percent.clamp(1.0, 100.0);

    if let Some(backlight_dir) = first_dir("/sys/class/backlight", |_| true) {
        if let Some(max) = read_trimmed(backlight_dir.join("max_brightness"))
            .and_then(|value| value.parse::<u32>().ok())
        {
            let target = ((percent / 100.0) * max as f32).round().max(1.0) as u32;
            if fs::write(backlight_dir.join("brightness"), target.to_string()).is_ok() {
                return Ok(());
            }
        }
    }

    run_command({
        let mut command = Command::new("brightnessctl");
        command.args(["set", &format!("{percent:.0}%")]);
        command
    })
    .map_err(|err| format!("{err}; essaye d'installer brightnessctl ou de régler les permissions"))
}

pub fn read_auto() -> bool {
    read_trimmed(auto_brightness_file()).is_some_and(|value| value == "enabled")
}

pub fn set_auto(enabled: bool) -> Result<bool, String> {
    if enabled && read_ambient_lux().is_none() {
        return Err("capteur de luminosité introuvable".to_string());
    }

    let path = auto_brightness_file();
    let Some(parent) = path.parent() else {
        return Err("chemin de configuration invalide".to_string());
    };

    fs::create_dir_all(parent).map_err(|err| err.to_string())?;
    fs::write(path, if enabled { "enabled\n" } else { "disabled\n" })
        .map_err(|err| err.to_string())?;

    if enabled {
        apply_auto()?;
    }

    Ok(enabled)
}

pub fn apply_auto() -> Result<(), String> {
    let lux = read_ambient_lux().ok_or_else(|| "capteur de luminosité introuvable".to_string())?;
    let target = match lux {
        value if value < 5.0 => 22.0,
        value if value < 30.0 => 35.0,
        value if value < 100.0 => 50.0,
        value if value < 300.0 => 65.0,
        value if value < 800.0 => 80.0,
        _ => 95.0,
    };

    set_percent(target)
}

fn auto_brightness_file() -> PathBuf {
    let config_home = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".config")))
        .unwrap_or_else(|| PathBuf::from("."));

    config_home.join("glassdeck").join("auto-brightness")
}

fn read_ambient_lux() -> Option<f32> {
    let devices = fs::read_dir("/sys/bus/iio/devices").ok()?;

    for device in devices.filter_map(Result::ok).map(|entry| entry.path()) {
        let raw_path = device.join("in_illuminance_raw");
        let input_path = device.join("in_illuminance_input");

        if let Some(input) = read_trimmed(&input_path).and_then(|value| value.parse::<f32>().ok()) {
            return Some(input);
        }

        let Some(raw) = read_trimmed(&raw_path).and_then(|value| value.parse::<f32>().ok()) else {
            continue;
        };

        let scale = read_trimmed(device.join("in_illuminance_scale"))
            .and_then(|value| value.parse::<f32>().ok())
            .unwrap_or(1.0);

        return Some(raw * scale);
    }

    None
}
