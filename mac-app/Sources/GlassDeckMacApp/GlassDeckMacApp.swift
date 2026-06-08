import SwiftUI

@main
struct GlassDeckMacApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 980, height: 680)
    }
}

struct DashboardView: View {
    @State private var model = DaemonModel()

    var body: some View {
        NavigationSplitView {
            Sidebar()
        } detail: {
            ZStack {
                GlassDeckBackground()

                VStack(spacing: 18) {
                    Header(model: model) {
                        Task {
                            await model.refresh()
                        }
                    }

                    HStack(alignment: .top, spacing: 18) {
                        ActionGrid(model: model)
                        DetailPanel(model: model)
                    }
                }
                .padding(24)
            }
        }
        .task {
            await model.refresh()
        }
    }
}

struct Sidebar: View {
    var body: some View {
        VStack(spacing: 14) {
            SidebarButton(symbol: "command", active: true)
            SidebarButton(symbol: "square.grid.2x2", active: false)
            SidebarButton(symbol: "bolt", active: false)
            SidebarButton(symbol: "gearshape", active: false)
            Spacer()
        }
        .padding(.vertical, 18)
        .frame(minWidth: 82)
        .background(.regularMaterial)
    }
}

struct SidebarButton: View {
    let symbol: String
    let active: Bool

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 48, height: 48)
            .background(active ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct Header: View {
    let model: DaemonModel
    let refresh: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("GlassDeck")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("Mac Control Center")
                    .font(.system(size: 34, weight: .bold))
            }

            Spacer()

            StatusPill(title: "Daemon", value: model.isOnline ? "Connecte" : "Hors ligne")
            StatusPill(title: "Actions", value: "\(model.actions.count)")

            Button(action: refresh) {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct StatusPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .frame(width: 118, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ActionGrid: View {
    let model: DaemonModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actions disponibles")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 14)], spacing: 14) {
                ForEach(model.actions) { action in
                    Button {
                        Task {
                            await model.execute(action)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 16) {
                            Image(systemName: icon(for: action.id))
                                .font(.system(size: 22, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                            Spacer()

                            Text(action.label)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(2)
                            Text(action.kind.displayName)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .frame(minHeight: 150)
                        .padding(16)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func icon(for actionId: String) -> String {
        switch actionId {
        case "ping": "dot.radiowaves.left.and.right"
        case "status": "gauge.with.dots.needle.67percent"
        case "open-url": "safari"
        case "open-applications": "square.grid.3x3"
        default: "command"
        }
    }
}

struct DetailPanel: View {
    let model: DaemonModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Derniere action")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(model.lastTitle)
                    .font(.title2.bold())
            }

            Text(model.lastMessage)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            HStack(spacing: 10) {
                Metric(title: "Clients", value: "\(model.connectedClients)")
                Metric(title: "Uptime", value: model.uptimeLabel)
            }
        }
        .frame(width: 280)
        .padding(18)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

struct Metric: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GlassDeckBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.06),
                Color(red: 0.10, green: 0.10, blue: 0.12),
                Color(red: 0.03, green: 0.05, blue: 0.04),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

@Observable
@MainActor
final class DaemonModel {
    var actions: [ActionDescriptor] = ActionDescriptor.fallback
    var connectedClients = 0
    var uptimeSeconds = 0
    var isOnline = false
    var lastTitle = "Pret"
    var lastMessage = "Le Mac attend le daemon GlassDeck."

    private let baseURL = URL(string: "http://127.0.0.1:7878")!

    var uptimeLabel: String {
        uptimeSeconds < 60 ? "\(uptimeSeconds)s" : "\(uptimeSeconds / 60)m"
    }

    func refresh() async {
        do {
            let url = baseURL.appending(path: "status")
            let (data, _) = try await URLSession.shared.data(from: url)
            let status = try JSONDecoder().decode(StatusSnapshot.self, from: data)

            actions = status.availableActions
            connectedClients = status.connectedClients
            uptimeSeconds = status.uptimeSeconds
            isOnline = true
            lastTitle = status.daemonName
            lastMessage = "Actions synchronisees."
        } catch {
            isOnline = false
            actions = ActionDescriptor.fallback
            lastTitle = "Daemon hors ligne"
            lastMessage = error.localizedDescription
        }
    }

    func execute(_ action: ActionDescriptor) async {
        do {
            lastTitle = action.label
            lastMessage = "Execution en cours..."

            let command = CommandRequest(
                requestId: UUID().uuidString,
                actionId: action.id,
                payload: action.id == "open-url" ? ["url": "https://www.apple.com"] : [:]
            )
            var request = URLRequest(url: baseURL.appending(path: "command"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(command)

            let (data, _) = try await URLSession.shared.data(for: request)
            let result = try JSONDecoder().decode(CommandResult.self, from: data)
            isOnline = true
            lastMessage = result.message
        } catch {
            isOnline = false
            lastMessage = error.localizedDescription
        }
    }
}

struct StatusSnapshot: Decodable {
    let daemonName: String
    let uptimeSeconds: Int
    let connectedClients: Int
    let availableActions: [ActionDescriptor]

    enum CodingKeys: String, CodingKey {
        case daemonName = "daemon_name"
        case uptimeSeconds = "uptime_seconds"
        case connectedClients = "connected_clients"
        case availableActions = "available_actions"
    }
}

struct ActionDescriptor: Decodable, Identifiable {
    let id: String
    let label: String
    let kind: ActionKind

    static let fallback = [
        ActionDescriptor(id: "ping", label: "Tester la connexion", kind: .system),
        ActionDescriptor(id: "status", label: "Lire l'etat du daemon", kind: .system),
        ActionDescriptor(id: "open-url", label: "Ouvrir Apple", kind: .application),
        ActionDescriptor(id: "open-applications", label: "Applications", kind: .application),
    ]
}

enum ActionKind: String, Decodable {
    case system
    case application
    case script

    var displayName: String {
        switch self {
        case .system: "Systeme"
        case .application: "Application"
        case .script: "Script"
        }
    }
}

struct CommandRequest: Encodable {
    let requestId: String
    let actionId: String
    let payload: [String: String]

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case actionId = "action_id"
        case payload
    }
}

struct CommandResult: Decodable {
    let message: String
}
