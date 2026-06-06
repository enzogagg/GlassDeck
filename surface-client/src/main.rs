slint::slint! {
    export component MainWindow inherits Window {
        width: 800px;
        height: 600px;
        background: #1e1e1e;

        Text {
            text: "GlassDeck Initialisé 🚀";
            color: white;
            font-size: 24px;
            font-weight: 700;
        }
    }
}

fn main() -> Result<(), slint::PlatformError> {
    println!("📱 [Surface Client] Démarrage de l'interface tactile...");
    let ui = MainWindow::new()?;
    ui.run()
}