with open("/Users/enzogaggiotti/Library/CloudStorage/SynologyDrive-Personnel/Infrastructure/GlassDeck/mac-daemon/Sources/GlassDeckMacDaemon/main.swift", "r") as f:
    content = f.read()

old_actions = """            Action(
                descriptor: ActionDescriptor(id: "open-applications", label: "Ouvrir Applications", kind: .application),
                handler: .runCommand(program: "open", arguments: ["/Applications"])
            ),
        ]"""

new_actions = """            Action(
                descriptor: ActionDescriptor(id: "open-applications", label: "Ouvrir Applications", kind: .application),
                handler: .runCommand(program: "open", arguments: ["/Applications"])
            ),
            Action(
                descriptor: ActionDescriptor(id: "open-app", label: "Ouvrir Application Spécifique", kind: .application),
                handler: .openApp
            ),
        ]"""

content = content.replace(old_actions, new_actions)

old_enum = """    case ping
    case status
    case openURL
    case runCommand(program: String, arguments: [String])"""

new_enum = """    case ping
    case status
    case openURL
    case openApp
    case runCommand(program: String, arguments: [String])"""

content = content.replace(old_enum, new_enum)

old_switch = """        case .openURL:
            guard case .object(let object) = payload,"""

new_switch = """        case .openApp:
            guard case .object(let object) = payload,
                  case .string(let appName)? = object["app"]
            else {
                return .failure("Payload attendu: {\\"app\\":\\"NomDeLApp\\"}")
            }
            return run(program: "open", arguments: ["-a", appName])
        case .openURL:
            guard case .object(let object) = payload,"""

content = content.replace(old_switch, new_switch)

with open("/Users/enzogaggiotti/Library/CloudStorage/SynologyDrive-Personnel/Infrastructure/GlassDeck/mac-daemon/Sources/GlassDeckMacDaemon/main.swift", "w") as f:
    f.write(content)
