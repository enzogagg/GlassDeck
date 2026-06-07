slint::slint! {
    import { LineEdit, Slider, Switch } from "std-widgets.slint";

    component MetricCard inherits Rectangle {
        in property <string> label;
        in property <string> value;
        in property <string> detail;
        in property <string> symbol;
        in property <brush> accent: #0a84ff;

        background: #24262b;
        border-radius: 28px;
        opacity: 0.94;

        Rectangle {
            x: 22px;
            y: 22px;
            width: 54px;
            height: 54px;
            border-radius: 18px;
            background: accent;
            Text {
                text: symbol;
                color: white;
                font-size: 26px;
                font-weight: 700;
                horizontal-alignment: center;
                vertical-alignment: center;
            }
        }

        Text {
            x: 92px;
            y: 22px;
            text: label;
            color: #ffffffa8;
            font-size: 15px;
            font-weight: 600;
        }

        Text {
            x: 92px;
            y: 46px;
            width: parent.width - 112px;
            text: value;
            color: white;
            font-size: 30px;
            font-weight: 800;
            overflow: elide;
        }

        Text {
            x: 24px;
            y: parent.height - 39px;
            width: parent.width - 48px;
            text: detail;
            color: #ffffff8f;
            font-size: 15px;
            overflow: elide;
        }
    }

    component CapsuleButton inherits Rectangle {
        in property <string> label;
        in property <string> symbol;
        in property <brush> tint: #2f3137;
        callback activated();

        background: touch.pressed ? #4a4d55 : tint;
        border-radius: 20px;

        Text {
            x: 18px;
            y: 0px;
            height: parent.height;
            text: symbol;
            color: white;
            font-size: 20px;
            font-weight: 700;
            vertical-alignment: center;
        }

        Text {
            x: 50px;
            y: 0px;
            width: parent.width - 66px;
            height: parent.height;
            text: label;
            color: white;
            font-size: 16px;
            font-weight: 700;
            vertical-alignment: center;
            overflow: elide;
        }

        touch := TouchArea {
            clicked => { root.activated(); }
        }
    }

    export component MainWindow inherits Window {
        width: 1024px;
        height: 720px;
        background: #0b0d12;
        title: "GlassDeck";

        in-out property <int> battery-percent: 0;
        in property <string> battery-state: "Inconnue";
        in property <bool> battery-charging: false;
        in property <string> network-name: "Hors ligne";
        in property <string> network-state: "Non connecté";
        in property <string> ip-address: "Aucune IP";
        in-out property <float> brightness: 0;
        in property <bool> auto-brightness: false;
        in property <string> status-message: "Prêt";
        in-out property <string> wifi-ssid: "";
        in-out property <string> wifi-password: "";

        callback refresh();
        callback connect-wifi(string, string);
        callback toggle-wifi();
        callback set-brightness(float);
        callback toggle-auto-brightness();

        Rectangle {
            x: -80px;
            y: -120px;
            width: 470px;
            height: 470px;
            border-radius: 235px;
            background: #1d5cff;
            opacity: 0.16;
        }

        Rectangle {
            x: 680px;
            y: 420px;
            width: 420px;
            height: 420px;
            border-radius: 210px;
            background: #30d158;
            opacity: 0.10;
        }

        Text {
            x: 46px;
            y: 34px;
            text: "GlassDeck";
            color: white;
            font-size: 42px;
            font-weight: 900;
        }

        Text {
            x: 48px;
            y: 84px;
            text: "Centre de contrôle Surface";
            color: #ffffff99;
            font-size: 19px;
            font-weight: 600;
        }

        Text {
            x: 760px;
            y: 48px;
            width: 218px;
            text: status-message;
            color: #ffffffa8;
            font-size: 15px;
            horizontal-alignment: right;
            overflow: elide;
        }

        CapsuleButton {
            x: 788px;
            y: 78px;
            width: 190px;
            height: 48px;
            label: "Actualiser";
            symbol: "↻";
            tint: #1e3a5f;
            activated => { root.refresh(); }
        }

        MetricCard {
            x: 46px;
            y: 150px;
            width: 290px;
            height: 170px;
            label: "Batterie";
            value: battery-percent + "%";
            detail: battery-state;
            symbol: battery-charging ? "⚡" : "▰";
            accent: battery-charging ? #30d158 : battery-percent < 20 ? #ff453a : #0a84ff;
        }

        MetricCard {
            x: 366px;
            y: 150px;
            width: 290px;
            height: 170px;
            label: "Réseau";
            value: network-name;
            detail: network-state;
            symbol: "⌁";
            accent: network-state == "Connecté" ? #30d158 : #ff9f0a;
        }

        MetricCard {
            x: 686px;
            y: 150px;
            width: 292px;
            height: 170px;
            label: "Adresse IP";
            value: ip-address;
            detail: "Interface active";
            symbol: "IP";
            accent: #5e5ce6;
        }

        Rectangle {
            x: 46px;
            y: 348px;
            width: 456px;
            height: 318px;
            border-radius: 32px;
            background: #24262b;
            opacity: 0.94;

            Text {
                x: 28px;
                y: 26px;
                text: "Wi‑Fi";
                color: white;
                font-size: 30px;
                font-weight: 850;
            }

            Text {
                x: 28px;
                y: 67px;
                width: parent.width - 56px;
                text: "Connexion rapide via NetworkManager";
                color: #ffffff8f;
                font-size: 16px;
            }

            LineEdit {
                x: 28px;
                y: 112px;
                width: parent.width - 56px;
                height: 48px;
                placeholder-text: "Nom du réseau";
                text <=> root.wifi-ssid;
            }

            LineEdit {
                x: 28px;
                y: 174px;
                width: parent.width - 56px;
                height: 48px;
                placeholder-text: "Mot de passe";
                input-type: InputType.password;
                text <=> root.wifi-password;
            }

            CapsuleButton {
                x: 28px;
                y: 246px;
                width: 188px;
                height: 48px;
                label: "Connecter";
                symbol: "✓";
                tint: #0a84ff;
                activated => { root.connect-wifi(root.wifi-ssid, root.wifi-password); }
            }

            CapsuleButton {
                x: 236px;
                y: 246px;
                width: 192px;
                height: 48px;
                label: "Wi‑Fi on/off";
                symbol: "⌁";
                tint: #383b42;
                activated => { root.toggle-wifi(); }
            }
        }

        Rectangle {
            x: 532px;
            y: 348px;
            width: 446px;
            height: 318px;
            border-radius: 32px;
            background: #24262b;
            opacity: 0.94;

            Text {
                x: 28px;
                y: 26px;
                text: "Écran";
                color: white;
                font-size: 30px;
                font-weight: 850;
            }

            Text {
                x: 28px;
                y: 67px;
                text: "Luminosité";
                color: #ffffff8f;
                font-size: 16px;
            }

            Text {
                x: parent.width - 126px;
                y: 64px;
                width: 98px;
                text: round(root.brightness) + "%";
                color: white;
                font-size: 20px;
                font-weight: 800;
                horizontal-alignment: right;
            }

            Slider {
                x: 28px;
                y: 108px;
                width: parent.width - 56px;
                height: 48px;
                minimum: 1;
                maximum: 100;
                value <=> root.brightness;
                changed => { root.set-brightness(self.value); }
            }

            Rectangle {
                x: 28px;
                y: 184px;
                width: parent.width - 56px;
                height: 76px;
                border-radius: 24px;
                background: #30333a;

                Text {
                    x: 22px;
                    y: 15px;
                    text: "Luminosité auto";
                    color: white;
                    font-size: 19px;
                    font-weight: 750;
                }

                Text {
                    x: 22px;
                    y: 42px;
                    text: root.auto-brightness ? "Activée" : "Désactivée";
                    color: #ffffff8f;
                    font-size: 15px;
                }

                Switch {
                    x: parent.width - 84px;
                    y: 22px;
                    checked: root.auto-brightness;
                    toggled => { root.toggle-auto-brightness(); }
                }
            }
        }
    }
}
