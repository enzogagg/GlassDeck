import re

with open("/Users/enzogaggiotti/Library/CloudStorage/SynologyDrive-Personnel/Infrastructure/GlassDeck/mac-daemon/Sources/GlassDeckMacDaemon/main.swift", "r") as f:
    content = f.read()

# Add AppKit import
content = content.replace("import Foundation\nimport Darwin\nimport Network\n", "import Foundation\nimport Darwin\nimport Network\nimport AppKit\n")

# Update DashboardStore.mainDashboard
old_main_dash = """    func mainDashboard() -> DashboardDefinition {
        dashboard
    }"""
new_main_dash = """    func mainDashboard() -> DashboardDefinition {
        let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Finder"
        
        var currentDashboard = dashboard
        // Insert title card
        currentDashboard.cards.insert(DashboardCard(
            id: "title-card",
            type: .title,
            title: activeApp,
            subtitle: "App ouverte",
            entity: nil,
            action: nil,
            x: 0,
            y: 0,
            w: 12,
            h: 1
        ), at: 0)
        
        // Shift existing cards down by 1 row
        for i in 1..<currentDashboard.cards.count {
            currentDashboard.cards[i].y += 1
        }
        
        // Add specific cards based on app
        if activeApp.lowercased() == "docker" || activeApp.lowercased() == "orbstack" || activeApp.lowercased() == "warp" {
            currentDashboard.cards.append(DashboardCard(
                id: "docker-status",
                type: .status,
                title: "Docker",
                subtitle: "Containers en cours",
                entity: "docker.status",
                action: nil,
                x: 0,
                y: 3,
                w: 6,
                h: 2
            ))
            currentDashboard.cards.append(DashboardCard(
                id: "k8s-status",
                type: .status,
                title: "Kubernetes",
                subtitle: "Cluster actif",
                entity: "kubernetes.status",
                action: nil,
                x: 6,
                y: 3,
                w: 6,
                h: 2
            ))
        }

        return currentDashboard
    }"""

content = content.replace(old_main_dash, new_main_dash)

# Update DashboardCardType
old_enum = """enum DashboardCardType: String, Codable {
    case metric
    case button
    case status
}"""
new_enum = """enum DashboardCardType: String, Codable {
    case metric
    case button
    case status
    case title
}"""

content = content.replace(old_enum, new_enum)

with open("/Users/enzogaggiotti/Library/CloudStorage/SynologyDrive-Personnel/Infrastructure/GlassDeck/mac-daemon/Sources/GlassDeckMacDaemon/main.swift", "w") as f:
    f.write(content)
