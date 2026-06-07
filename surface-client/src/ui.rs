slint::slint! {
    import { LineEdit, Slider, Switch } from "std-widgets.slint";

    component GlassPanel inherits Rectangle {
        in property <brush> panel-background: #1c1c1ecc;

        background: panel-background;
        border-radius: 34px;
        border-width: 1px;
        border-color: #ffffff24;
    }

    component CapsuleButton inherits Rectangle {
        in property <string> label;
        in property <string> symbol;
        in property <brush> tint: #ffffff18;
        callback activated();

        background: touch.pressed ? #ffffff30 : tint;
        border-radius: 24px;
        border-width: 1px;
        border-color: #ffffff1f;

        Text {
            x: 22px;
            width: 34px;
            height: parent.height;
            text: symbol;
            color: white;
            font-size: 25px;
            font-weight: 800;
            horizontal-alignment: center;
            vertical-alignment: center;
        }

        Text {
            x: 68px;
            width: parent.width - 88px;
            height: parent.height;
            text: label;
            color: white;
            font-size: 19px;
            font-weight: 750;
            vertical-alignment: center;
            overflow: elide;
        }

        touch := TouchArea {
            clicked => { root.activated(); }
        }
    }

    component StatusPill inherits Rectangle {
        in property <string> label;
        in property <string> value;
        in property <string> symbol;
        in property <brush> accent: #0a84ff;

        background: #ffffff14;
        border-radius: 28px;
        border-width: 1px;
        border-color: #ffffff1b;

        Rectangle {
            x: 18px;
            y: 17px;
            width: 52px;
            height: 52px;
            border-radius: 26px;
            background: accent;

            Text {
                text: symbol;
                color: white;
                font-size: 25px;
                font-weight: 850;
                horizontal-alignment: center;
                vertical-alignment: center;
            }
        }

        Text {
            x: 88px;
            y: 18px;
            width: parent.width - 108px;
            text: label;
            color: #ffffff92;
            font-size: 16px;
            font-weight: 650;
            overflow: elide;
        }

        Text {
            x: 88px;
            y: 43px;
            width: parent.width - 108px;
            text: value;
            color: white;
            font-size: 25px;
            font-weight: 850;
            overflow: elide;
        }
    }

    component BatteryColumn inherits Rectangle {
        in property <int> percent: 0;
        in property <bool> charging: false;

        background: #ffffff12;
        border-radius: 44px;
        border-width: 1px;
        border-color: #ffffff25;

        Rectangle {
            x: 18px;
            y: 18px;
            width: parent.width - 36px;
            height: parent.height - 36px;
            border-radius: 32px;
            background: #07080dcc;
            border-width: 1px;
            border-color: #ffffff18;

            Rectangle {
                x: 8px;
                width: parent.width - 16px;
                height: (parent.height - 16px) * root.percent / 100;
                y: parent.height - 8px - self.height;
                border-radius: 24px;
                background: root.charging ? #30d158 : root.percent < 20 ? #ff453a : #0a84ff;
            }
        }
    }

    component PageDots inherits Rectangle {
        in property <int> active-page: 0;

        background: #00000000;

        Rectangle {
            x: 0px;
            y: 0px;
            width: root.active-page == 0 ? 30px : 10px;
            height: 10px;
            border-radius: 5px;
            background: root.active-page == 0 ? #ffffffd6 : #ffffff52;
        }

        Rectangle {
            x: 40px;
            y: 0px;
            width: root.active-page == 1 ? 30px : 10px;
            height: 10px;
            border-radius: 5px;
            background: root.active-page == 1 ? #ffffffd6 : #ffffff52;
        }
    }

    export component MainWindow inherits Window {
        width: 1024px;
        height: 720px;
        background: #050507;
        title: "GlassDeck";

        in-out property <int> active-page: 0;
        in-out property <int> battery-percent: 0;
        in property <string> battery-state: "Inconnue";
        in property <bool> battery-charging: false;
        in property <string> network-name: "Wi‑Fi";
        in property <string> network-state: "Non connecté";
        in property <string> ip-address: "Aucune IP";
        in-out property <float> brightness: 0;
        in property <bool> auto-brightness: false;
        in property <string> status-message: "Prêt";
        in-out property <string> wifi-ssid: "";
        in-out property <string> wifi-password: "";

        callback connect-wifi(string, string);
        callback toggle-wifi();
        callback set-brightness(float);
        callback toggle-auto-brightness();

        Rectangle {
            x: -170px;
            y: -190px;
            width: 610px;
            height: 610px;
            border-radius: 305px;
            background: #0a84ff;
            opacity: 0.22;
        }

        Rectangle {
            x: 680px;
            y: 390px;
            width: 500px;
            height: 500px;
            border-radius: 250px;
            background: #30d158;
            opacity: 0.12;
        }

        Rectangle {
            x: root.active-page == 0 ? 0px : -1024px;
            y: 0px;
            width: 2048px;
            height: 720px;
            animate x { duration: 260ms; }

            Rectangle {
                x: 0px;
                y: 0px;
                width: 1024px;
                height: 720px;
                background: #00000000;

                Text {
                    x: 58px;
                    y: 58px;
                    text: "GlassDeck";
                    color: white;
                    font-size: 64px;
                    font-weight: 900;
                }

                Text {
                    x: 62px;
                    y: 135px;
                    text: "Surface";
                    color: #ffffff9e;
                    font-size: 28px;
                    font-weight: 700;
                }

                GlassPanel {
                    x: 58px;
                    y: 220px;
                    width: 430px;
                    height: 300px;
                    panel-background: #ffffff14;

                    Text {
                        x: 34px;
                        y: 30px;
                        text: battery-charging ? "En charge" : "Batterie";
                        color: #ffffffa8;
                        font-size: 24px;
                        font-weight: 700;
                    }

                    Text {
                        x: 32px;
                        y: 72px;
                        text: battery-percent + "%";
                        color: white;
                        font-size: 104px;
                        font-weight: 900;
                    }

                    Text {
                        x: 38px;
                        y: 200px;
                        width: 228px;
                        text: battery-state;
                        color: #ffffff9c;
                        font-size: 24px;
                        font-weight: 650;
                        overflow: elide;
                    }

                    BatteryColumn {
                        x: 306px;
                        y: 34px;
                        width: 82px;
                        height: 232px;
                        percent: battery-percent;
                        charging: battery-charging;
                    }
                }

                GlassPanel {
                    x: 520px;
                    y: 220px;
                    width: 446px;
                    height: 300px;
                    panel-background: #ffffff12;

                    Text {
                        x: 34px;
                        y: 30px;
                        text: "Connectivité";
                        color: white;
                        font-size: 34px;
                        font-weight: 850;
                    }

                    Text {
                        x: 36px;
                        y: 92px;
                        width: parent.width - 72px;
                        text: network-name;
                        color: white;
                        font-size: 42px;
                        font-weight: 900;
                        overflow: elide;
                    }

                    Text {
                        x: 38px;
                        y: 145px;
                        width: parent.width - 76px;
                        text: network-state;
                        color: #ffffff9c;
                        font-size: 24px;
                        font-weight: 650;
                    }

                    Text {
                        x: 38px;
                        y: 205px;
                        width: parent.width - 76px;
                        text: ip-address;
                        color: #ffffffd9;
                        font-size: 31px;
                        font-weight: 800;
                    }
                }

                Text {
                    x: 58px;
                    y: 606px;
                    width: 820px;
                    text: status-message;
                    color: #ffffff72;
                    font-size: 19px;
                    font-weight: 650;
                    overflow: elide;
                }
            }

            Rectangle {
                x: 1024px;
                y: 0px;
                width: 1024px;
                height: 720px;
                background: #00000000;

                Text {
                    x: 50px;
                    y: 40px;
                    text: "Centre de contrôle";
                    color: white;
                    font-size: 46px;
                    font-weight: 900;
                }

                Text {
                    x: 52px;
                    y: 98px;
                    width: 560px;
                    text: status-message;
                    color: #ffffff8f;
                    font-size: 19px;
                    font-weight: 650;
                    overflow: elide;
                }

                GlassPanel {
                    x: 50px;
                    y: 150px;
                    width: 330px;
                    height: 512px;
                    panel-background: #ffffff14;

                    Text {
                        x: 32px;
                        y: 28px;
                        text: battery-charging ? "Charge" : "Batterie";
                        color: #ffffff9c;
                        font-size: 25px;
                        font-weight: 700;
                    }

                    Text {
                        x: 28px;
                        y: 68px;
                        text: battery-percent + "%";
                        color: white;
                        font-size: 82px;
                        font-weight: 900;
                    }

                    BatteryColumn {
                        x: 210px;
                        y: 40px;
                        width: 76px;
                        height: 330px;
                        percent: battery-percent;
                        charging: battery-charging;
                    }

                    Text {
                        x: 32px;
                        y: 390px;
                        width: parent.width - 64px;
                        text: battery-state;
                        color: #ffffff9c;
                        font-size: 24px;
                        font-weight: 650;
                    }

                    StatusPill {
                        x: 28px;
                        y: 436px;
                        width: parent.width - 56px;
                        height: 58px;
                        label: "Alimentation";
                        value: battery-charging ? "Branchée" : "Sur batterie";
                        symbol: battery-charging ? "↯" : "▰";
                        accent: battery-charging ? #30d158 : #0a84ff;
                    }
                }

                GlassPanel {
                    x: 410px;
                    y: 150px;
                    width: 564px;
                    height: 246px;
                    panel-background: #ffffff12;

                    StatusPill {
                        x: 26px;
                        y: 24px;
                        width: 512px;
                        height: 88px;
                        label: "Wi‑Fi";
                        value: network-name;
                        symbol: "⌁";
                        accent: network-state == "Connecté" ? #30d158 : #ff9f0a;
                    }

                    Text {
                        x: 36px;
                        y: 130px;
                        text: "Adresse IP";
                        color: #ffffff91;
                        font-size: 20px;
                        font-weight: 700;
                    }

                    Text {
                        x: 36px;
                        y: 162px;
                        width: parent.width - 72px;
                        text: ip-address;
                        color: white;
                        font-size: 34px;
                        font-weight: 850;
                    }
                }

                GlassPanel {
                    x: 410px;
                    y: 420px;
                    width: 272px;
                    height: 242px;
                    panel-background: #ffffff12;

                    Text {
                        x: 26px;
                        y: 24px;
                        text: "Wi‑Fi";
                        color: white;
                        font-size: 31px;
                        font-weight: 850;
                    }

                    LineEdit {
                        x: 24px;
                        y: 78px;
                        width: parent.width - 48px;
                        height: 52px;
                        placeholder-text: "Réseau";
                        text <=> root.wifi-ssid;
                    }

                    LineEdit {
                        x: 24px;
                        y: 142px;
                        width: parent.width - 48px;
                        height: 52px;
                        placeholder-text: "Mot de passe";
                        input-type: InputType.password;
                        text <=> root.wifi-password;
                    }

                    CapsuleButton {
                        x: 24px;
                        y: 204px;
                        width: 106px;
                        height: 52px;
                        label: "Joindre";
                        symbol: "+";
                        tint: #0a84ff;
                        activated => { root.connect-wifi(root.wifi-ssid, root.wifi-password); }
                    }

                    CapsuleButton {
                        x: 144px;
                        y: 204px;
                        width: 104px;
                        height: 52px;
                        label: "Radio";
                        symbol: "⌁";
                        tint: #ffffff18;
                        activated => { root.toggle-wifi(); }
                    }
                }

                GlassPanel {
                    x: 706px;
                    y: 420px;
                    width: 268px;
                    height: 242px;
                    panel-background: #ffffff12;

                    Text {
                        x: 26px;
                        y: 24px;
                        text: "Écran";
                        color: white;
                        font-size: 31px;
                        font-weight: 850;
                    }

                    Text {
                        x: 26px;
                        y: 75px;
                        text: round(root.brightness) + "%";
                        color: white;
                        font-size: 45px;
                        font-weight: 900;
                    }

                    Slider {
                        x: 24px;
                        y: 134px;
                        width: parent.width - 48px;
                        height: 52px;
                        minimum: 1;
                        maximum: 100;
                        value <=> root.brightness;
                        changed => { root.set-brightness(self.value); }
                    }

                    Rectangle {
                        x: 24px;
                        y: 190px;
                        width: parent.width - 48px;
                        height: 40px;
                        background: #00000000;

                        Text {
                            x: 0px;
                            width: 148px;
                            height: parent.height;
                            text: "Auto";
                            color: #ffffffc9;
                            font-size: 20px;
                            font-weight: 750;
                            vertical-alignment: center;
                        }

                        Switch {
                            x: parent.width - 56px;
                            y: 2px;
                            checked: root.auto-brightness;
                            toggled => { root.toggle-auto-brightness(); }
                        }
                    }
                }
            }
        }

        PageDots {
            x: 477px;
            y: 670px;
            width: 70px;
            height: 10px;
            active-page: root.active-page;
        }

        Rectangle {
            x: 0px;
            y: 638px;
            width: 1024px;
            height: 82px;
            background: #00000000;

            touch := TouchArea {
                moved => {
                    if (self.mouse-x - self.pressed-x < -120px) {
                        root.active-page = 1;
                    }
                    if (self.mouse-x - self.pressed-x > 120px) {
                        root.active-page = 0;
                    }
                }
            }
        }
    }
}
