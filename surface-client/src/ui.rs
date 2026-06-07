slint::slint! {
    import { Switch } from "std-widgets.slint";

    component GlassPanel inherits Rectangle {
        in property <brush> panel-background: #1c1c1ecc;
        in property <length> corner-radius: 34px;

        background: panel-background;
        border-radius: corner-radius;
        border-width: 1px;
        border-color: #ffffff24;
    }

    component CapsuleButton inherits Rectangle {
        in property <string> label;
        in property <string> symbol;
        in property <brush> tint: #ffffff18;
        callback activated();

        background: button_touch.pressed ? #ffffff30 : tint;
        border-radius: 24px;
        border-width: 1px;
        border-color: #ffffff1f;

        Text {
            x: 18px;
            width: 34px;
            height: parent.height;
            text: symbol;
            color: white;
            font-size: 23px;
            font-weight: 800;
            horizontal-alignment: center;
            vertical-alignment: center;
        }

        Text {
            x: 60px;
            width: parent.width - 74px;
            height: parent.height;
            text: label;
            color: white;
            font-size: 18px;
            font-weight: 750;
            vertical-alignment: center;
            overflow: elide;
        }

        button_touch := TouchArea {
            clicked => { root.activated(); }
        }
    }

    component BatteryMenuBar inherits Rectangle {
        in property <int> percent: 0;
        in property <bool> charging: false;

        background: #00000000;

        Rectangle {
            x: 0px;
            y: 8px;
            width: 48px;
            height: 17px;
            border-radius: 4px;
            border-width: 1px;
            border-color: #ffffffd8;
            background: #00000000;

            Rectangle {
                x: 3px;
                y: 3px;
                width: 40px * root.percent / 100;
                height: 9px;
                border-radius: 2px;
                background: root.charging ? #30d158 : root.percent < 20 ? #ff453a : #ffffffe8;
            }
        }

        Rectangle {
            x: 50px;
            y: 13px;
            width: 2px;
            height: 6px;
            border-radius: 2px;
            background: #ffffffd8;
        }

        Text {
            x: 60px;
            width: parent.width - 60px;
            height: parent.height;
            text: root.percent + "%";
            color: white;
            font-size: 16px;
            font-weight: 800;
            vertical-alignment: center;
            horizontal-alignment: right;
        }
    }

    component BatteryColumn inherits Rectangle {
        in property <int> percent: 0;
        in property <bool> charging: false;

        background: #ffffff12;
        border-radius: 38px;
        border-width: 1px;
        border-color: #ffffff25;

        Rectangle {
            x: 16px;
            y: 16px;
            width: parent.width - 32px;
            height: parent.height - 32px;
            border-radius: 28px;
            background: #07080dcc;
            border-width: 1px;
            border-color: #ffffff18;

            Rectangle {
                x: 7px;
                width: parent.width - 14px;
                height: (parent.height - 14px) * root.percent / 100;
                y: parent.height - 7px - self.height;
                border-radius: 22px;
                background: root.charging ? #30d158 : root.percent < 20 ? #ff453a : #0a84ff;
            }
        }
    }

    component StatusTile inherits Rectangle {
        in property <string> label;
        in property <string> value;
        in property <string> symbol;
        in property <brush> accent: #0a84ff;

        background: #ffffff16;
        border-radius: 30px;
        border-width: 1px;
        border-color: #ffffff1f;

        Rectangle {
            x: 24px;
            y: 23px;
            width: 58px;
            height: 58px;
            border-radius: 29px;
            background: accent;

            Text {
                text: symbol;
                color: white;
                font-size: 27px;
                font-weight: 850;
                horizontal-alignment: center;
                vertical-alignment: center;
            }
        }

        Text {
            x: 104px;
            y: 24px;
            width: parent.width - 128px;
            text: label;
            color: #ffffff9c;
            font-size: 17px;
            font-weight: 700;
            overflow: elide;
        }

        Text {
            x: 104px;
            y: 52px;
            width: parent.width - 128px;
            text: value;
            color: white;
            font-size: 28px;
            font-weight: 850;
            overflow: elide;
        }
    }

    export component MainWindow inherits Window {
        width: 1024px;
        height: 720px;
        background: #050507;
        title: "GlassDeck";

        in-out property <bool> control-center-open: false;
        in-out property <int> battery-percent: 0;
        in property <string> battery-state: "Inconnue";
        in property <bool> battery-charging: false;
        in property <string> network-name: "Wi‑Fi";
        in property <string> network-state: "Non connecté";
        in property <string> ip-address: "Aucune IP";
        in-out property <float> brightness: 0;
        in property <bool> auto-brightness: false;
        in property <string> status-message: "Prêt";
        callback set-brightness(float);
        callback adjust-brightness(float);
        callback toggle-auto-brightness();
        callback request-exit();

        Rectangle {
            x: 0px;
            y: 0px;
            width: 1024px;
            height: 720px;
            background: #050506;
        }

        Rectangle {
            x: 0px;
            y: 60px;
            width: 1024px;
            height: 220px;
            background: #151517;
            opacity: 0.96;
        }

        Rectangle {
            x: 0px;
            y: 280px;
            width: 1024px;
            height: 220px;
            background: #0e0f12;
            opacity: 0.98;
        }

        Rectangle {
            x: 0px;
            y: 500px;
            width: 1024px;
            height: 220px;
            background: #1c1c1e;
            opacity: 0.88;
        }

        Rectangle {
            x: 0px;
            y: 0px;
            width: 1024px;
            height: 60px;
            background: #06070acc;
            border-width: 0px;

            Text {
                x: 28px;
                width: 240px;
                height: parent.height;
                text: "GlassDeck";
                color: white;
                font-size: 22px;
                font-weight: 850;
                vertical-alignment: center;
            }

            Text {
                x: 394px;
                width: 236px;
                height: parent.height;
                text: "Surface";
                color: #ffffffb8;
                font-size: 18px;
                font-weight: 700;
                horizontal-alignment: center;
                vertical-alignment: center;
            }

            Text {
                x: 696px;
                width: 104px;
                height: parent.height;
                text: network-state == "Connecté" ? network-name : network-state;
                color: #ffffffb8;
                font-size: 17px;
                font-weight: 700;
                horizontal-alignment: right;
                vertical-alignment: center;
                overflow: elide;
            }

            BatteryMenuBar {
                x: 860px;
                y: 14px;
                width: 134px;
                height: 32px;
                percent: battery-percent;
                charging: battery-charging;
            }
        }

        Rectangle {
            x: 0px;
            y: 60px;
            width: 1024px;
            height: 660px;
            background: #00000000;

            Text {
                x: 58px;
                y: 92px;
                text: "GlassDeck";
                color: white;
                font-size: 74px;
                font-weight: 900;
            }

            Text {
                x: 62px;
                y: 184px;
                width: 630px;
                text: "Surface";
                color: #ffffff9e;
                font-size: 34px;
                font-weight: 700;
            }

            Text {
                x: 64px;
                y: 506px;
                width: 680px;
                text: "Surface";
                color: #ffffff4f;
                font-size: 22px;
                font-weight: 650;
                overflow: elide;
            }
        }

        Rectangle {
            x: 0px;
            y: 0px;
            width: 1024px;
            height: 130px;
            background: #00000000;

            top_swipe := TouchArea {
                clicked => {
                    root.control-center-open = true;
                }
                moved => {
                    if (self.mouse-y - self.pressed-y > 34px) {
                        root.control-center-open = true;
                    }
                }
            }
        }

        Rectangle {
            x: 0px;
            y: root.control-center-open ? 0px : -720px;
            width: 1024px;
            height: 720px;
            background: #050507e8;
            animate y { duration: 260ms; }

            Rectangle {
                x: -90px;
                y: -160px;
                width: 520px;
                height: 520px;
                border-radius: 260px;
                background: #0a84ff;
                opacity: 0.24;
            }

            Rectangle {
                x: 698px;
                y: 410px;
                width: 420px;
                height: 420px;
                border-radius: 210px;
                background: #30d158;
                opacity: 0.13;
            }

            close_swipe := TouchArea {
                moved => {
                    if (self.mouse-y - self.pressed-y < -42px) {
                        root.control-center-open = false;
                    }
                }
            }

            Text {
                x: 50px;
                y: 42px;
                text: "Centre de contrôle";
                color: white;
                font-size: 48px;
                font-weight: 900;
            }

            Text {
                x: 54px;
                y: 104px;
                width: 720px;
                text: status-message;
                color: #ffffff93;
                font-size: 20px;
                font-weight: 650;
                overflow: elide;
            }

            CapsuleButton {
                x: 806px;
                y: 44px;
                width: 168px;
                height: 52px;
                label: "Quitter";
                symbol: "X";
                tint: #ffffff18;
                activated => { root.request-exit(); }
            }

            GlassPanel {
                x: 50px;
                y: 154px;
                width: 330px;
                height: 506px;
                panel-background: #ffffff16;
                corner-radius: 38px;

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
                    width: 176px;
                    text: battery-percent + "%";
                    color: white;
                    font-size: 76px;
                    font-weight: 900;
                }

                BatteryColumn {
                    x: 246px;
                    y: 0px;
                    width: 84px;
                    height: 506px;
                    percent: battery-percent;
                    charging: battery-charging;
                }

                Text {
                    x: 32px;
                    y: 388px;
                    width: parent.width - 64px;
                    text: battery-state;
                    color: #ffffff9c;
                    font-size: 24px;
                    font-weight: 650;
                }

                Text {
                    x: 32px;
                    y: 436px;
                    width: parent.width - 64px;
                    text: battery-charging ? "Branchée" : "Sur batterie";
                    color: #ffffffd8;
                    font-size: 24px;
                    font-weight: 800;
                }
            }

            GlassPanel {
                x: 410px;
                y: 154px;
                width: 564px;
                height: 246px;
                panel-background: #ffffff14;
                corner-radius: 38px;

                StatusTile {
                    x: 26px;
                    y: 24px;
                    width: 512px;
                    height: 104px;
                    label: "Connexion";
                    value: network-state == "Connecté" ? network-name : network-state;
                    symbol: "⌁";
                    accent: network-state == "Connecté" ? #30d158 : #ff9f0a;
                }

                Text {
                    x: 36px;
                    y: 148px;
                    text: "Adresse IP";
                    color: #ffffff91;
                    font-size: 20px;
                    font-weight: 700;
                }

                Text {
                    x: 36px;
                    y: 180px;
                    width: parent.width - 72px;
                    text: ip-address;
                    color: white;
                    font-size: 34px;
                    font-weight: 850;
                }
            }

            GlassPanel {
                x: 410px;
                y: 424px;
                width: 250px;
                height: 236px;
                panel-background: #ffffff14;
                corner-radius: 34px;

                Text {
                    x: 26px;
                    y: 22px;
                    text: "Réseau";
                    color: white;
                    font-size: 31px;
                    font-weight: 850;
                }

                Text {
                    x: 26px;
                    y: 78px;
                    width: parent.width - 52px;
                    text: network-state == "Connecté" ? network-name : network-state;
                    color: white;
                    font-size: 28px;
                    font-weight: 850;
                    overflow: elide;
                }

                Text {
                    x: 26px;
                    y: 120px;
                    width: parent.width - 52px;
                    text: network-state == "Connecté" ? "Connecté" : "Aucune connexion";
                    color: #ffffffa0;
                    font-size: 20px;
                    font-weight: 700;
                    overflow: elide;
                }

                Text {
                    x: 26px;
                    y: 174px;
                    width: parent.width - 52px;
                    text: ip-address;
                    color: #ffffffd8;
                    font-size: 23px;
                    font-weight: 800;
                    overflow: elide;
                }
            }

            GlassPanel {
                x: 684px;
                y: 424px;
                width: 290px;
                height: 236px;
                panel-background: #ffffff14;
                corner-radius: 34px;

                Text {
                    x: 26px;
                    y: 22px;
                    text: "Écran";
                    color: white;
                    font-size: 31px;
                    font-weight: 850;
                }

                Text {
                    x: 26px;
                    y: 72px;
                    text: round(root.brightness) + "%";
                    color: white;
                    font-size: 50px;
                    font-weight: 900;
                }

                Rectangle {
                    x: 24px;
                    y: 132px;
                    width: parent.width - 48px;
                    height: 28px;
                    border-radius: 14px;
                    background: #ffffff24;

                    Rectangle {
                        width: parent.width * root.brightness / 100;
                        height: parent.height;
                        border-radius: 14px;
                        background: #f5f5f7;
                    }
                }

                Rectangle {
                    x: 24px;
                    y: 112px;
                    width: 121px;
                    height: 76px;
                    background: #00000000;

                    decrease_touch := TouchArea {
                        clicked => { root.adjust-brightness(-10); }
                    }
                }

                Rectangle {
                    x: 145px;
                    y: 112px;
                    width: 121px;
                    height: 76px;
                    background: #00000000;

                    increase_touch := TouchArea {
                        clicked => { root.adjust-brightness(10); }
                    }
                }

                Rectangle {
                    x: 24px;
                    y: 194px;
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

            Rectangle {
                x: 462px;
                y: 692px;
                width: 100px;
                height: 6px;
                border-radius: 3px;
                background: #ffffff70;
            }
        }
    }
}
