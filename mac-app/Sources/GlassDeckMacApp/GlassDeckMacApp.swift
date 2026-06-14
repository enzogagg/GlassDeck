import SwiftUI

@main
struct GlassDeckMacApp: App {
    @State private var model = GlassDeckStudioModel()

    var body: some Scene {
        WindowGroup {
            StudioView(model: model)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1360, height: 860)

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
                        if model.activeSurface == .dashboard {
                            DashboardCanvas(model: model)
                        } else {
                            ControlCenterCanvas(model: model)
                        }
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
        VStack(spacing: 16) {
            LogoBadge()

            Capsule()
                .fill(.white.opacity(0.14))
                .frame(width: 30, height: 3)

            SurfaceRailButton(
                symbol: "rectangle.grid.3x2",
                title: "Board",
                active: model.activeSurface == .dashboard
            ) {
                model.activeSurface = .dashboard
            }

            SurfaceRailButton(
                symbol: "switch.2",
                title: "Control",
                active: model.activeSurface == .controlCenter
            ) {
                model.activeSurface = .controlCenter
            }

            Spacer()

            VStack(spacing: 8) {
                Circle()
                    .fill(model.isOnline ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                    .shadow(color: model.isOnline ? .green.opacity(0.45) : .orange.opacity(0.35), radius: 8)
                Text(model.isOnline ? "On" : "Off")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 22)
        .frame(minWidth: 72)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.10), Color.white.opacity(0.035)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
    }
}

struct SurfaceRailButton: View {
    let symbol: String
    let title: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 40)
                    .background(active ? Color.accentColor.opacity(0.24) : Color.white.opacity(0.055))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(active ? Color.accentColor.opacity(0.7) : .white.opacity(0.06), lineWidth: 1)
                    )
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(active ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .help(title)
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

struct StudioHeader: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("GlassDeck Studio")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(model.activeSurface == .dashboard ? "Canvas" : "Control Center")
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
                    Text("Glisse les cartes sur la grille, puis publie vers la Surface")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            CardLibrary(model: model)

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

struct CardLibrary: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        HStack(spacing: 10) {
            LibraryCard(symbol: "chart.line.uptrend.xyaxis", title: "Métrique", subtitle: "CPU, RAM, température") {
                model.addCard(type: .metric)
            }
            LibraryCard(symbol: "checkmark.circle", title: "Statut", subtitle: "Connexion, état") {
                model.addCard(type: .status)
            }
            LibraryCard(symbol: "button.programmable", title: "Bouton", subtitle: "Action Mac") {
                model.addCard(type: .button)
            }
            Spacer()
            Text("Ajoute une carte, puis déplace-la sur la grille.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(Color.black.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct LibraryCard: View {
    let symbol: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.semibold))
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.055))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct DashboardPreviewLayout: View {
    @Bindable var model: GlassDeckStudioModel
    @State private var draggingCardID: String?
    @State private var dragTranslation: CGSize = .zero

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
                    let isDragging = draggingCardID == card.id

                    Button {
                        model.selectedCardID = card.id
                    } label: {
                        CanvasCard(card: card, value: model.previewValue(for: card))
                            .frame(width: width, height: height)
                            .scaleEffect(isDragging ? 1.035 : 1)
                            .shadow(color: isDragging ? .black.opacity(0.34) : .clear, radius: 18, y: 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(model.selectedCardID == card.id ? Color.accentColor : .clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .offset(isDragging ? dragTranslation : .zero)
                    .position(x: originX + width / 2, y: originY + height / 2)
                    .zIndex(isDragging ? 10 : 1)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                model.selectedCardID = card.id
                                draggingCardID = card.id
                                dragTranslation = value.translation
                            }
                            .onEnded { value in
                                model.moveCard(
                                    id: card.id,
                                    translation: value.translation,
                                    cellWidth: cellWidth,
                                    rowHeight: rowHeight,
                                    gap: gap
                                )
                                draggingCardID = nil
                                dragTranslation = .zero
                            }
                    )
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

struct ControlCenterCanvas: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Centre de contrôle")
                        .font(.title2.bold())
                    Text("Aperçu du panneau latéral affiché sur la Surface")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    model.addControlCenterCard()
                } label: {
                    Label("Ajouter une carte", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(spacing: 12) {
                    ControlCenterPreviewHeader(model: model)
                    ControlCenterPreviewGrid(model: model)
                    ControlCenterPreviewSliders()
                }
                .padding(18)
                .frame(maxWidth: 460, alignment: .top)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), Color.white.opacity(0.055)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .overlay(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 10) {
                    Label("Synchronisation automatique", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                    Text("Les cartes configurées ici sont incluses dans le dashboard publié. La Surface les recharge automatiquement et garde la dernière version valide si le Mac disparaît quelques secondes.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.black.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            .frame(maxHeight: .infinity, alignment: .top)
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

struct ControlCenterPreviewHeader: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("GlassDeck")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text("Centre de contrôle")
                    .font(.headline)
            }
            Spacer()
            Text(model.isOnline ? "Mac connecté" : "Mac hors ligne")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(4)
    }
}

struct ControlCenterPreviewGrid: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
            ForEach(model.dashboard.controlCenterCards) { card in
                Button {
                    model.selectedControlCenterCardID = card.id
                } label: {
                    ControlCenterPreviewCard(card: card, value: model.previewValue(for: card))
                }
                .buttonStyle(.plain)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(model.selectedControlCenterCardID == card.id ? Color.accentColor : .clear, lineWidth: 2)
                )
            }
        }
    }
}

struct ControlCenterPreviewCard: View {
    let card: DashboardCard
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(card.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(card.type == .button ? "Action" : value)
                .font(.system(size: 20, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(card.subtitle ?? card.entity ?? card.action ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(minHeight: 86, maxHeight: 86, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.075))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

struct ControlCenterPreviewSliders: View {
    var body: some View {
        VStack(spacing: 10) {
            PreviewSlider(title: "Luminosité", value: "100%")
            PreviewSlider(title: "Volume", value: "70%")
        }
    }
}

struct PreviewSlider: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.caption.weight(.semibold))
            }
            Capsule()
                .fill(.white.opacity(0.1))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: title == "Luminosité" ? 210 : 150, height: 8)
                }
        }
        .padding(12)
        .background(Color.white.opacity(0.055))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct InspectorPanel: View {
    @Bindable var model: GlassDeckStudioModel

    var selectedDashboardIndex: Int? {
        model.dashboard.cards.firstIndex { $0.id == model.selectedCardID }
    }

    var selectedControlCenterIndex: Int? {
        model.dashboard.controlCenterCards.firstIndex { $0.id == model.selectedControlCenterCardID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if model.activeSurface == .dashboard {
                    SectionHeader(title: "Dashboard", subtitle: "Nom, grille et publication")

                    GlassPanel {
                        TextField("Nom", text: $model.dashboard.name)
                        Stepper("Colonnes: \(model.dashboard.grid.columns)", value: $model.dashboard.grid.columns, in: 4...16)
                        Stepper("Hauteur ligne: \(model.dashboard.grid.rowHeight)", value: $model.dashboard.grid.rowHeight, in: 44...120, step: 4)
                        Stepper("Espacement: \(model.dashboard.grid.gap)", value: $model.dashboard.grid.gap, in: 6...24)
                    }

                    SectionHeader(title: "Carte sélectionnée", subtitle: "Position, entité et action")

                    if let selectedDashboardIndex {
                        CardEditor(card: $model.dashboard.cards[selectedDashboardIndex], model: model)
                    } else {
                        EmptyInspector(text: "Sélectionne une carte du dashboard")
                    }

                    SectionHeader(title: "Barre horizontale du bas", subtitle: "Boutons visibles sur la Surface")
                    DockEditor(model: model)
                } else {
                    SectionHeader(title: "Centre de contrôle", subtitle: "Cartes visibles dans le panneau Surface")

                    if let selectedControlCenterIndex {
                        ControlCenterSingleCardEditor(card: $model.dashboard.controlCenterCards[selectedControlCenterIndex], model: model)
                    } else {
                        EmptyInspector(text: "Sélectionne une carte du centre de contrôle")
                    }

                    SectionHeader(title: "Toutes les cartes", subtitle: "Ordre et contenu du panneau")
                    ControlCenterCardListEditor(model: model)
                }

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

struct ControlCenterSingleCardEditor: View {
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

            if card.type == .button {
                Picker("Action", selection: stringBinding($card.action, fallback: "ping")) {
                    ForEach(model.actions) { action in
                        Text(action.label).tag(action.id)
                    }
                }
            } else {
                Picker("Entité", selection: stringBinding($card.entity, fallback: "mac.cpu_percent")) {
                    ForEach(DashboardEntity.allCases) { entity in
                        Text(entity.title).tag(entity.rawValue)
                    }
                }
            }

            Button(role: .destructive) {
                model.deleteControlCenterCard(card.id)
            } label: {
                Label("Supprimer la carte", systemImage: "trash")
            }
        }
    }
}

struct ControlCenterCardListEditor: View {
    @Bindable var model: GlassDeckStudioModel

    var body: some View {
        GlassPanel {
            ForEach($model.dashboard.controlCenterCards) { $card in
                Button {
                    model.selectedControlCenterCardID = card.id
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: card.type.symbol)
                            .frame(width: 26)
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(card.title)
                                .font(.callout.weight(.semibold))
                            Text(card.subtitle ?? card.entity ?? card.action ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                model.addControlCenterCard()
            } label: {
                Label("Ajouter une carte", systemImage: "plus")
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
    var text = "Sélectionne une carte"

    var body: some View {
        GlassPanel {
            Text(text)
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
    var activeSurface: StudioSurface = .dashboard
    var actions: [ActionDescriptor] = ActionDescriptor.fallback
    var dashboard = DashboardDefinition.defaultMain
    var selectedCardID: String? = DashboardDefinition.defaultMain.cards.first?.id
    var selectedControlCenterCardID: String? = DashboardDefinition.defaultMain.controlCenterCards.first?.id
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
            selectedControlCenterCardID = dashboard.controlCenterCards.first?.id
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
            encoder.keyEncodingStrategy = .convertToSnakeCase
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

    func addCard(type: DashboardCardType = .metric) {
        activeSurface = .dashboard
        let nextPosition = nextCardPosition(width: type == .button ? 3 : 3, height: 2)
        let card = DashboardCard(
            id: "card-\(UUID().uuidString.prefix(8))",
            type: type,
            title: defaultTitle(for: type),
            subtitle: defaultSubtitle(for: type),
            entity: type == .button ? nil : "mac.cpu_percent",
            action: type == .button ? (actions.first?.id ?? "ping") : nil,
            x: nextPosition.x,
            y: nextPosition.y,
            w: 3,
            h: 2
        )
        dashboard.cards.append(card)
        selectedCardID = card.id
    }

    func moveCard(id: String, translation: CGSize, cellWidth: CGFloat, rowHeight: CGFloat, gap: CGFloat) {
        guard let index = dashboard.cards.firstIndex(where: { $0.id == id }) else { return }

        let columnStep = max(1, cellWidth + gap)
        let rowStep = max(1, rowHeight + gap)
        let deltaX = Int((translation.width / columnStep).rounded())
        let deltaY = Int((translation.height / rowStep).rounded())
        guard deltaX != 0 || deltaY != 0 else { return }

        var card = dashboard.cards[index]
        let maxX = max(0, dashboard.grid.columns - card.w)
        card.x = min(max(0, card.x + deltaX), maxX)
        card.y = min(max(0, card.y + deltaY), 12)
        dashboard.cards[index] = card
    }

    private func nextCardPosition(width: Int, height: Int) -> (x: Int, y: Int) {
        let columns = max(1, dashboard.grid.columns)
        for y in 0...12 {
            for x in 0...max(0, columns - width) {
                let candidate = DashboardRect(x: x, y: y, w: width, h: height)
                if dashboard.cards.allSatisfy({ !candidate.intersects(DashboardRect(card: $0)) }) {
                    return (x, y)
                }
            }
        }
        return (0, max(0, (dashboard.cards.map { $0.y + $0.h }.max() ?? 0)))
    }

    private func defaultTitle(for type: DashboardCardType) -> String {
        switch type {
        case .metric: "Métrique"
        case .status: "Statut Mac"
        case .button: "Action"
        }
    }

    private func defaultSubtitle(for type: DashboardCardType) -> String {
        switch type {
        case .metric: "Entité Mac"
        case .status: "Connexion"
        case .button: "Commande Mac"
        }
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

    func addControlCenterCard() {
        activeSurface = .controlCenter
        let card = DashboardCard(
            id: "control-\(UUID().uuidString.prefix(8))",
            type: .metric,
            title: "Nouvelle carte",
            subtitle: "Centre de contrôle",
            entity: "mac.cpu_percent",
            action: nil,
            x: 0,
            y: 0,
            w: 1,
            h: 1
        )
        dashboard.controlCenterCards.append(card)
        selectedControlCenterCardID = card.id
    }

    func deleteControlCenterCard(_ id: String) {
        dashboard.controlCenterCards.removeAll { $0.id == id }
        if selectedControlCenterCardID == id {
            selectedControlCenterCardID = dashboard.controlCenterCards.first?.id
        }
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
    var controlCenterCards: [DashboardCard]

    init(
        id: String,
        name: String,
        grid: DashboardGrid,
        cards: [DashboardCard],
        dockActions: [DashboardDockAction],
        controlCenterCards: [DashboardCard]
    ) {
        self.id = id
        self.name = name
        self.grid = grid
        self.cards = cards
        self.dockActions = dockActions
        self.controlCenterCards = controlCenterCards
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case grid
        case cards
        case dockActions
        case controlCenterCards
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        grid = try container.decode(DashboardGrid.self, forKey: .grid)
        cards = try container.decode([DashboardCard].self, forKey: .cards)
        dockActions = try container.decodeIfPresent([DashboardDockAction].self, forKey: .dockActions) ?? DashboardDefinition.defaultDockActions
        controlCenterCards = try container.decodeIfPresent([DashboardCard].self, forKey: .controlCenterCards) ?? DashboardDefinition.defaultControlCenterCards
    }

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
        dockActions: defaultDockActions,
        controlCenterCards: defaultControlCenterCards
    )

    static let defaultDockActions = [
            DashboardDockAction(id: "dock-ping", title: "Ping", action: "ping"),
            DashboardDockAction(id: "dock-apps", title: "Apps", action: "open-applications"),
            DashboardDockAction(id: "dock-sync", title: "Sync", action: "status"),
    ]

    static let defaultControlCenterCards = [
        DashboardCard(id: "control-cpu", type: .metric, title: "CPU", subtitle: "Utilisation Mac", entity: "mac.cpu_percent", action: nil, x: 0, y: 0, w: 1, h: 1),
        DashboardCard(id: "control-memory", type: .metric, title: "RAM", subtitle: "Mémoire utilisée", entity: "mac.memory_percent", action: nil, x: 0, y: 0, w: 1, h: 1),
        DashboardCard(id: "control-temperature", type: .metric, title: "Température", subtitle: "Capteur Mac", entity: "mac.temperature_celsius", action: nil, x: 0, y: 0, w: 1, h: 1),
    ]
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

struct DashboardRect {
    let x: Int
    let y: Int
    let w: Int
    let h: Int

    init(x: Int, y: Int, w: Int, h: Int) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }

    init(card: DashboardCard) {
        self.init(x: card.x, y: card.y, w: card.w, h: card.h)
    }

    func intersects(_ other: DashboardRect) -> Bool {
        x < other.x + other.w &&
            x + w > other.x &&
            y < other.y + other.h &&
            y + h > other.y
    }
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

enum StudioSurface {
    case dashboard
    case controlCenter
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
