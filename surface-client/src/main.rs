mod system;
mod ui;

use slint::{ComponentHandle, SharedString, Timer, TimerMode};
use std::time::Duration;
use system::{brightness, read_system_snapshot, SystemSnapshot};
use ui::MainWindow;

fn main() -> Result<(), slint::PlatformError> {
    println!("[Surface Client] Starting GlassDeck control center...");

    let ui = MainWindow::new()?;
    apply_snapshot(&ui, read_system_snapshot("Prêt"));
    let _refresh_timer = register_refresh_timer(&ui);
    register_actions(&ui);

    ui.run()
}

fn register_refresh_timer(ui: &MainWindow) -> Timer {
    let weak_ui = ui.as_weak();
    let timer = Timer::default();
    timer.start(TimerMode::Repeated, Duration::from_secs(1), move || {
        if let Some(ui) = weak_ui.upgrade() {
            apply_snapshot(&ui, read_system_snapshot("Synchronisé"));
        }
    });
    timer
}

fn register_actions(ui: &MainWindow) {
    ui.on_request_exit(|| {
        std::process::exit(0);
    });

    let weak_ui = ui.as_weak();
    ui.on_set_brightness(move |value| {
        let message = match brightness::set_percent(value) {
            Ok(()) => "Luminosité mise à jour".to_string(),
            Err(err) => format!("Luminosité: {err}"),
        };

        if let Some(ui) = weak_ui.upgrade() {
            apply_snapshot(&ui, read_system_snapshot(&message));
        }
    });

    let weak_ui = ui.as_weak();
    ui.on_toggle_auto_brightness(move || {
        let message = match brightness::set_auto(!brightness::read_auto()) {
            Ok(true) => "Luminosité auto activée".to_string(),
            Ok(false) => "Luminosité auto désactivée".to_string(),
            Err(err) => format!("Luminosité auto: {err}"),
        };

        if let Some(ui) = weak_ui.upgrade() {
            apply_snapshot(&ui, read_system_snapshot(&message));
        }
    });
}

fn apply_snapshot(ui: &MainWindow, snapshot: SystemSnapshot) {
    ui.set_battery_percent(snapshot.battery_percent);
    ui.set_battery_state(snapshot.battery_state.into());
    ui.set_battery_charging(snapshot.battery_charging);
    ui.set_network_name(snapshot.network_name.into());
    ui.set_network_state(snapshot.network_state.into());
    ui.set_ip_address(snapshot.ip_address.into());
    ui.set_brightness(snapshot.brightness);
    ui.set_auto_brightness(snapshot.auto_brightness);
    ui.set_status_message(SharedString::from(snapshot.status_message));
}
