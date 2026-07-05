with open("/Users/enzogaggiotti/Library/CloudStorage/SynologyDrive-Personnel/Infrastructure/GlassDeck/mac-daemon/Sources/GlassDeckMacDaemon/main.swift", "r") as f:
    content = f.read()

old_struct = """struct DashboardCard: Codable {
    let id: String
    let type: DashboardCardType
    let title: String
    let subtitle: String?
    let entity: String?
    let action: String?
    let x: Int
    let y: Int
    let w: Int
    let h: Int
}"""

new_struct = """struct DashboardCard: Codable {
    var id: String
    var type: DashboardCardType
    var title: String
    var subtitle: String?
    var entity: String?
    var action: String?
    var x: Int
    var y: Int
    var w: Int
    var h: Int
}"""

content = content.replace(old_struct, new_struct)

with open("/Users/enzogaggiotti/Library/CloudStorage/SynologyDrive-Personnel/Infrastructure/GlassDeck/mac-daemon/Sources/GlassDeckMacDaemon/main.swift", "w") as f:
    f.write(content)
