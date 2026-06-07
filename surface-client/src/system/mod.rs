pub mod brightness;
mod command;
mod fs_util;
pub mod network;
mod power;

#[derive(Default)]
pub struct SystemSnapshot {
    pub battery_percent: i32,
    pub battery_state: String,
    pub battery_charging: bool,
    pub network_name: String,
    pub network_state: String,
    pub ip_address: String,
    pub brightness: f32,
    pub auto_brightness: bool,
    pub status_message: String,
}

pub fn read_system_snapshot(status_message: &str) -> SystemSnapshot {
    if brightness::read_auto() {
        let _ = brightness::apply_auto();
    }

    let battery = power::read_battery();
    let network = network::read_network();

    SystemSnapshot {
        battery_percent: battery.percent,
        battery_state: battery.state,
        battery_charging: battery.charging,
        network_name: network.name,
        network_state: network.state,
        ip_address: network::read_ip_address(),
        brightness: brightness::read_percent().unwrap_or(0.0),
        auto_brightness: brightness::read_auto(),
        status_message: status_message.to_string(),
    }
}
