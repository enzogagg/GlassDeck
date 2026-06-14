import SwiftUI

@main
struct GlassDeckMacApp: App {
    @State private var model = GlassDeckStudioModel()

    var body: some Scene {
        WindowGroup {
            StudioView(model: model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1180, height: 760)

        MenuBarExtra("GlassDeck", systemImage: "rectangle.connected.to.line.below") {
            Button(model.isOnline ? "Daemon connecté" : "Daemon hors ligne") {
                Task { await model.refreshAll() }
            }
            Divider()
            Button("Publier le dashboard") {
                Task { await model.publishDashboard() }
            }
            Divider()
            Button("Démarrer le daemon") {
                Task { await model.controlService(.start) }
            }
            Button("Redémarrer le daemon") {
                Task { await model.controlService(.restart) }
            }
            Button("Arrêter le daemon") {
                Task { await model.controlService(.stop) }
            }
        }
    }
}

struct StudioView: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        NavigationSplitView {
            StudioSidebar(model: model)
        } detail: {
            ZStack {
                StudioBackground()

                VStack(spacing: 18) {
                    StudioHeader(model: model)

                    HStack(alignment: .top, spacing: 18) {
                        DashboardCanvas(model: model)
                        InspectorPanel(model: model)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(22)
            }
        }
        .task {
            await model.refreshAll()
        }
    }
}

struct StudioSidebar: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        VStack(spacing: 14) {
            LogoBadge()
                .padding(.bottom, 10)

            SidebarButton(symbol: "rectangle.grid.3x2", title: "Dashboard", active: true)
            SidebarButton(symbol: "dock.rectangle", title: "Dock", active: false)
            SidebarButton(symbol: "bolt.horizontal", title: "Actions", active: false)

            Spacer()

            Circle()
                .fill(model.isOnline ? Color.green : Color.orange)
                .frame(width: 10, height: 10)
                .shadow(color: model.isOnline ? .green.opacity(0.45) : .orange.opacity(0.35), radius: 8)
        }
        .padding(.vertical, 20)
        .frame(minWidth: 92)
        .background(.ultraThinMaterial)
    }
}

struct LogoBadge: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color(red: 0.45, green: 0.78, blue: 1),
                            Color.accentColor,
                            Color(red: 0.0, green: 0.28, blue: 0.82),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.32), radius: 18, y: 10)

            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.95))
                    .frame(width: 24, height: 4)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.9))
                    .frame(width: 24, height: 4)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.white.opacity(0.82))
                    .frame(width: 16, height: 4)
            }
        }
        .frame(width: 48, height: 48)
    }
}

struct SidebarButton: View {
    let symbol: String
    let title: String
    let active: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 48, height: 44)
                .background(active ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 15))
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

struct StudioHeader: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("GlassDeck Studio")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text("Dashboard Surface")
                    .font(.system(size: 32, weight: .bold))
                    .lineLimit(1)
                Text(model.lastMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            StatusTile(title: "Daemon", value: model.isOnline ? "Connecté" : "Hors ligne", color: model.isOnline ? .green : .orange)
            StatusTile(title: "Surface", value: model.connectedClients > 0 ? "\(model.connectedClients) client" : "Aucune", color: .blue)
            StatusTile(title: "Cartes", value: "\(model.dashboard.cards.count)", color: .purple)

            Button {
                Task { await model.refreshAll() }
            } label: {
                Label("Actualiser", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Button {
                Task { await model.publishDashboard() }
            } label: {
                Label("Publier", systemImage: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct StatusTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .frame(width: 112, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct DashboardCanvas: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.dashboard.name)
                        .font(.title2.bold())
                    Text("Aperçu du dashboard envoyé à la Surface")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    model.addCard()
                } label: {
                    Label("Ajouter une carte", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            DashboardPreviewLayout(model: model)

            DockPreview(model: model)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DashboardPreviewLayout: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        GeometryReader { proxy in
            let grid = model.dashboard.grid
            let columns = max(1, grid.columns)
            let gap = CGFloat(max(6, grid.gap))
            let rowHeight = CGFloat(max(56, grid.rowHeight))
            let availableWidth = max(1, proxy.size.width)
            let cellWidth = max(42, (availableWidth - gap * CGFloat(columns - 1)) / CGFloat(columns))

            ZStack(alignment: .topLeading) {
                CanvasGridBackground(columns: columns, rows: model.previewRows, gap: gap, cellWidth: cellWidth, rowHeight: rowHeight)

                ForEach(model.dashboard.cards) { card in
                    let x = min(max(0, card.x), max(0, columns - 1))
                    let widthUnits = min(max(1, card.w), max(1, columns - x))
                    let heightUnits = max(1, card.h)
                    let width = cellWidth * CGFloat(widthUnits) + gap * CGFloat(widthUnits - 1)
                    let height = rowHeight * CGFloat(heightUnits) + gap * CGFloat(heightUnits - 1)
                    let originX = CGFloat(x) * (cellWidth + gap)
                    let originY = CGFloat(max(0, card.y)) * (rowHeight + gap)

                    Button {
                        model.selectedCardID = card.id
                    } label: {
                        CanvasCard(card: card, value: model.previewValue(for: card))
                            .frame(width: width, height: height)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(model.selectedCardID == card.id ? Color.accentColor : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .position(x: originX + width / 2, y: originY + height / 2)
                }
            }
        }
        .frame(height: model.previewCanvasHeight)
        .padding(12)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct CanvasGridBackground: View {
    let columns: Int
    let rows: Int
    let gap: CGFloat
    let cellWidth: CGFloat
    let rowHeight: CGFloat

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: gap) {
                    ForEach(0..<columns, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.025))
                            .frame(width: cellWidth, height: rowHeight)
                    }
                }
            }
        }
    }
}

struct CanvasCard: View {
    let card: DashboardCard
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(card.type.displayName, systemImage: card.type.symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleAndIcon)
                    .textCase(.uppercase)
                Spacer()
                if card.type == .button {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(.blue)
                }
            }

            Text(card.title)
                .font(.system(size: 18, weight: .semibold))
                .lineLimit(1)

            Text(value)
                .font(.system(size: card.type == .button ? 22 : 34, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer()

            Text(card.subtitle ?? card.entity ?? card.action ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.16), Color.white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct DockPreview: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Barre du bas")
                    .font(.headline)
                Text("Actions rapides envoyées à la Surface")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ForEach(model.dashboard.dockActions) { item in
                VStack(spacing: 6) {
                    Image(systemName: model.icon(for: item.action))
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 42, height: 42)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text(item.title)
                        .font(.caption2.weight(.semibold))
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.34), Color.black.opacity(0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct InspectorPanel: View {
    @Bindable var model: GlassDeckStudioModel

    var selectedIndex: Int? {
        model.dashboard.cards.firstIndex { $0.id == model.selectedCardID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Dashboard", subtitle: "Nom, grille et publication")

                GlassPanel {
                    TextField("Nom", text: $model.dashboard.name)
                    Stepper("Colonnes: \(model.dashboard.grid.columns)", value: $model.dashboard.grid.columns, in: 4...16)
                    Stepper("Hauteur ligne: \(model.dashboard.grid.rowHeight)", value: $model.dashboard.grid.rowHeight, in: 44...120, step: 4)
                    Stepper("Espacement: \(model.dashboard.grid.gap)", value: $model.dashboard.grid.gap, in: 6...24)
                }

                SectionHeader(title: "Carte sélectionnée", subtitle: "Position, entité et action")

                if let selectedIndex {
                    CardEditor(card: $model.dashboard.cards[selectedIndex], model: model)
                } else {
                    EmptyInspector()
                }

                SectionHeader(title: "Barre horizontale du bas", subtitle: "Boutons visibles sur la Surface")
                DockEditor(model: model)

                SectionHeader(title: "Daemon", subtitle: model.isOnline ? "Service local prêt" : "Service local indisponible")
                GlassPanel {
                    Text(model.lastMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button("Start") { Task { await model.controlService(.start) } }
                        Button("Restart") { Task { await model.controlService(.restart) } }
                        Button("Stop") { Task { await model.controlService(.stop) } }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(18)
        }
        .frame(width: 420)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct CardEditor: View {
    @Binding var card: DashboardCard
    let model: GlassDeckStudioModel

    var body: some View {
        GlassPanel {
            TextField("Titre", text: $card.title)
            TextField("Sous-titre", text: stringBinding($card.subtitle, fallback: ""))

            Picker("Type", selection: $card.type) {
                ForEach(DashboardCardType.allCases) { type in
                    Label(type.displayName, systemImage: type.symbol).tag(type)
                }
            }
            .pickerStyle(.segmented)

            Picker("Entité", selection: stringBinding($card.entity, fallback: "mac.cpu_percent")) {
                ForEach(DashboardEntity.allCases) { entity in
                    Text(entity.title).tag(entity.rawValue)
                }
            }

            Picker("Action", selection: stringBinding($card.action, fallback: "ping")) {
                ForEach(model.actions) { action in
                    Text(action.label).tag(action.id)
                }
            }

            VStack(spacing: 10) {
                HStack {
                    Stepper("X \(card.x)", value: $card.x, in: 0...11)
                    Stepper("Y \(card.y)", value: $card.y, in: 0...8)
                }
                HStack {
                    Stepper("W \(card.w)", value: $card.w, in: 1...12)
                    Stepper("H \(card.h)", value: $card.h, in: 1...4)
                }
            }

            Button(role: .destructive) {
                model.deleteSelectedCard()
            } label: {
                Label("Supprimer la carte", systemImage: "trash")
            }
        }
    }
}

func stringBinding(_ source: Binding<String?>, fallback: String) -> Binding<String> {
    Binding<String>(
        get: { source.wrappedValue ?? fallback },
        set: { source.wrappedValue = $0.isEmpty ? nil : $0 }
    )
}

struct DockEditor: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        GlassPanel {
            ForEach($model.dashboard.dockActions) { $item in
                HStack(spacing: 10) {
                    TextField("Titre", text: $item.title)
                        .frame(minWidth: 120)
                    Picker("Action", selection: $item.action) {
                        ForEach(model.actions) { action in
                            Text(action.label).tag(action.id)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .labelsHidden()
                    Button {
                        model.deleteDockAction(item.id)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }

            Button {
                model.addDockAction()
            } label: {
                Label("Ajouter un bouton", systemImage: "plus")
            }
        }
    }

}

struct GlassPanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

struct EmptyInspector: View {
    var body: some View {
        GlassPanel {
            Text("Sélectionne une carte")
                .font(.headline)
            Text("Clique une carte dans l’aperçu ou ajoute une nouvelle carte pour la configurer.")
                .foregroundStyle(.secondary)
        }
    }
}

struct StudioBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.025, blue: 0.035),
                    Color(red: 0.08, green: 0.085, blue: 0.105),
                    Color.black,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [.blue.opacity(0.16), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )
        }
        .ignoresSafeArea()
    }
}

@Observable
@MainActor
final class GlassDeckStudioModel {
    var actions: [ActionDescriptor] = ActionDescriptor.fallback
    var dashboard = DashboardDefinition.defaultMain
    var selectedCardID: String? = DashboardDefinition.defaultMain.cards.first?.id
    var connectedClients = 0
    var uptimeSeconds = 0
    var isOnline = false
    var lastMessage = "Prêt à configurer GlassDeck."

    private let baseURL = URL(string: "http://127.0.0.1:7878")!
    private let service = MacDaemonService()

    var previewRows: Int {
        max(4, (dashboard.cards.map { $0.y + $0.h }.max() ?? 4))
    }

    var previewCanvasHeight: CGFloat {
        let rowHeight = CGFloat(max(56, dashboard.grid.rowHeight))
        let gap = CGFloat(max(6, dashboard.grid.gap))
        return max(360, CGFloat(previewRows) * rowHeight + CGFloat(max(0, previewRows - 1)) * gap)
    }

    func refreshAll() async {
        await refreshStatus()
        await fetchDashboard()
    }

    func refreshStatus() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: baseURL.appending(path: "status"))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let status = try decoder.decode(StatusSnapshot.self, from: data)
            actions = status.availableActions
            connectedClients = status.connectedClients
            uptimeSeconds = status.uptimeSeconds
            isOnline = true
            lastMessage = "Daemon synchronisé."
        } catch {
            isOnline = false
            actions = ActionDescriptor.fallback
            lastMessage = "Daemon hors ligne: \(error.localizedDescription)"
        }
    }

    func fetchDashboard() async {
        do {
            let (data, response) = try await URLSession.shared.data(from: baseURL.appending(path: "dashboards/main"))
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StudioError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                throw StudioError.dashboardEndpointUnavailable(body?.isEmpty == false ? body! : "HTTP \(httpResponse.statusCode)")
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            dashboard = try decoder.decode(DashboardDefinition.self, from: data)
            selectedCardID = dashboard.cards.first?.id
            lastMessage = "Dashboard chargé depuis le daemon."
        } catch let error as StudioError {
            lastMessage = error.localizedDescription
        } catch {
            lastMessage = "Dashboard local conservé: \(error.localizedDescription)"
        }
    }

    func publishDashboard() async {
        do {
            var request = URLRequest(url: baseURL.appending(path: "dashboards/main"))
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(dashboard)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw StudioError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                let body = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                throw StudioError.dashboardEndpointUnavailable(body?.isEmpty == false ? body! : "HTTP \(httpResponse.statusCode)")
            }
            isOnline = true
            lastMessage = "Dashboard publié sur GlassDeck."
        } catch let error as StudioError {
            lastMessage = error.localizedDescription
        } catch {
            isOnline = false
            lastMessage = "Publication impossible: \(error.localizedDescription)"
        }
    }

    func addCard() {
        let card = DashboardCard(
            id: "card-\(UUID().uuidString.prefix(8))",
            type: .metric,
            title: "Nouvelle carte",
            subtitle: "Entité Mac",
            entity: "mac.cpu_percent",
            action: nil,
            x: 0,
            y: max(0, (dashboard.cards.map(\.y).max() ?? 0) + 2),
            w: 3,
            h: 2
        )
        dashboard.cards.append(card)
        selectedCardID = card.id
    }

    func deleteSelectedCard() {
        guard let selectedCardID else { return }
        dashboard.cards.removeAll { $0.id == selectedCardID }
        self.selectedCardID = dashboard.cards.first?.id
    }

    func addDockAction() {
        let action = actions.first?.id ?? "ping"
        dashboard.dockActions.append(DashboardDockAction(id: "dock-\(UUID().uuidString.prefix(8))", title: "Action", action: action))
    }

    func deleteDockAction(_ id: String) {
        dashboard.dockActions.removeAll { $0.id == id }
    }

    func previewValue(for card: DashboardCard) -> String {
        if card.type == .button {
            return "Action"
        }

        switch card.entity {
        case "mac.daemon":
            return isOnline ? "Connecté" : "Hors ligne"
        case "mac.cpu_percent":
            return "--%"
        case "mac.memory_percent":
            return "--%"
        case "mac.temperature_celsius":
            return "--°"
        default:
            return "--"
        }
    }

    func icon(for action: String) -> String {
        switch action {
        case "open-applications": "square.grid.3x3"
        case "open-url": "safari"
        case "status": "gauge.with.dots.needle.67percent"
        default: "dot.radiowaves.left.and.right"
        }
    }

    func controlService(_ command: MacDaemonService.Command) async {
        do {
            lastMessage = "Commande service en cours..."
            lastMessage = try await service.run(command)
            try? await Task.sleep(for: .milliseconds(400))
            await refreshAll()
        } catch {
            isOnline = false
            lastMessage = error.localizedDescription
        }
    }
}

struct DashboardDefinition: Codable {
    var id: String
    var name: String
    var grid: DashboardGrid
    var cards: [DashboardCard]
    var dockActions: [DashboardDockAction]

    static let defaultMain = DashboardDefinition(
        id: "main",
        name: "Principal",
        grid: DashboardGrid(columns: 12, rowHeight: 64, gap: 12),
        cards: [
            DashboardCard(id: "mac-status", type: .status, title: "Mac", subtitle: "Daemon GlassDeck", entity: "mac.daemon", action: nil, x: 0, y: 0, w: 3, h: 2),
            DashboardCard(id: "mac-cpu", type: .metric, title: "CPU", subtitle: "Utilisation", entity: "mac.cpu_percent", action: nil, x: 3, y: 0, w: 3, h: 2),
            DashboardCard(id: "mac-memory", type: .metric, title: "Mémoire", subtitle: "RAM utilisée", entity: "mac.memory_percent", action: nil, x: 6, y: 0, w: 3, h: 2),
            DashboardCard(id: "mac-temperature", type: .metric, title: "Température", subtitle: "Capteur Mac", entity: "mac.temperature_celsius", action: nil, x: 9, y: 0, w: 3, h: 2),
            DashboardCard(id: "open-apps", type: .button, title: "Applications", subtitle: "Ouvrir sur le Mac", entity: nil, action: "open-applications", x: 0, y: 2, w: 3, h: 2),
        ],
        dockActions: [
            DashboardDockAction(id: "dock-ping", title: "Ping", action: "ping"),
            DashboardDockAction(id: "dock-apps", title: "Apps", action: "open-applications"),
            DashboardDockAction(id: "dock-sync", title: "Sync", action: "status"),
        ]
    )
}

struct DashboardGrid: Codable {
    var columns: Int
    var rowHeight: Int
    var gap: Int
}

struct DashboardCard: Codable, Identifiable, Equatable {
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
}

struct DashboardDockAction: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var action: String
}

enum DashboardCardType: String, Codable, CaseIterable, Identifiable {
    case metric
    case status
    case button

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metric: "Métrique"
        case .status: "Statut"
        case .button: "Bouton"
        }
    }

    var symbol: String {
        switch self {
        case .metric: "chart.line.uptrend.xyaxis"
        case .status: "checkmark.circle"
        case .button: "button.programmable"
        }
    }
}

enum DashboardEntity: String, CaseIterable, Identifiable {
    case daemon = "mac.daemon"
    case cpu = "mac.cpu_percent"
    case memory = "mac.memory_percent"
    case temperature = "mac.temperature_celsius"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daemon: "Mac daemon"
        case .cpu: "CPU"
        case .memory: "Mémoire"
        case .temperature: "Température"
        }
    }
}

struct MacDaemonService {
    enum Command: String {
        case start
        case stop
        case restart
        case status
    }

    func run(_ command: Command) async throws -> String {
        let script = try serviceScriptURL()
        return try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["bash", script.path, command.rawValue]

            let output = Pipe()
            let error = Pipe()
            process.standardOutput = output
            process.standardError = error

            try process.run()
            process.waitUntilExit()

            let outputText = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let errorText = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard process.terminationStatus == 0 else {
                throw NSError(
                    domain: "GlassDeckMacDaemonService",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: errorText?.isEmpty == false ? errorText! : "Commande échouée"]
                )
            }

            return outputText?.isEmpty == false ? outputText! : "Commande exécutée."
        }.value
    }

    private func serviceScriptURL() throws -> URL {
        let current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let candidates = [
            current.appending(path: "../scripts/mac-daemon-service.sh"),
            current.appending(path: "scripts/mac-daemon-service.sh"),
            URL(fileURLWithPath: Bundle.main.bundlePath).appending(path: "../../../scripts/mac-daemon-service.sh"),
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate.standardized.path) {
            return candidate.standardized
        }

        throw NSError(
            domain: "GlassDeckMacDaemonService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "scripts/mac-daemon-service.sh introuvable."]
        )
    }
}

struct StatusSnapshot: Decodable {
    let daemonName: String
    let uptimeSeconds: Int
    let connectedClients: Int
    let availableActions: [ActionDescriptor]
}

struct ActionDescriptor: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let kind: ActionKind

    static let fallback = [
        ActionDescriptor(id: "ping", label: "Tester la connexion", kind: .system),
        ActionDescriptor(id: "status", label: "Lire l’état du daemon", kind: .system),
        ActionDescriptor(id: "open-url", label: "Ouvrir une URL", kind: .application),
        ActionDescriptor(id: "open-applications", label: "Applications", kind: .application),
    ]
}

enum ActionKind: String, Codable {
    case system
    case application
    case script
}

enum StudioError: LocalizedError {
    case invalidResponse
    case dashboardEndpointUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Réponse daemon invalide."
        case .dashboardEndpointUnavailable(let detail):
            "Daemon à mettre à jour: redémarre le daemon GlassDeck. Détail: \(detail)"
        }
    }
}
