import Foundation
import Network

let config = DaemonConfig.fromEnvironment()
let daemon = MacDaemon(config: config)
daemon.start()
RunLoop.main.run()

struct DaemonConfig {
    let host: String
    let port: UInt16

    static func fromEnvironment() -> Self {
        let rawValue = ProcessInfo.processInfo.environment["GLASSDECK_MAC_DAEMON_ADDR"]
            ?? "0.0.0.0:7878"
        let parts = rawValue.split(separator: ":", maxSplits: 1).map(String.init)
        let host = parts.first?.isEmpty == false ? parts[0] : "0.0.0.0"
        let port = parts.count > 1 ? UInt16(parts[1]) ?? 7878 : 7878
        return Self(host: host, port: port)
    }
}

final class MacDaemon: @unchecked Sendable {
    private let config: DaemonConfig
    private let startedAt = Date()
    private let queue = DispatchQueue(label: "glassdeck.mac-daemon")
    private let registry = ActionRegistry()
    private var listener: NWListener?
    private var connectedClients = 0

    init(config: DaemonConfig) {
        self.config = config
    }

    func start() {
        do {
            let parameters = NWParameters.tcp
            let listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: config.port)!)
            self.listener = listener

            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("[Mac Daemon] GlassDeck ecoute sur \(self.config.host):\(self.config.port)")
                    print("[Mac Daemon] \(self.registry.actions.count) actions disponibles")
                case .failed(let error):
                    fputs("[Mac Daemon] Echec listener: \(error)\n", stderr)
                    exit(1)
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }
            listener.start(queue: queue)
        } catch {
            fputs("[Mac Daemon] Impossible de demarrer: \(error)\n", stderr)
            exit(1)
        }
    }

    private func accept(_ connection: NWConnection) {
        connectedClients += 1
        print("[Mac Daemon] Client connecte")

        connection.stateUpdateHandler = { [weak self] state in
            if case .cancelled = state {
                self?.connectedClients -= 1
                print("[Mac Daemon] Client deconnecte")
            }
        }
        connection.start(queue: queue)
        receive(connection: connection, buffer: Data())
    }

    private func receive(connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { [weak self] data, _, isComplete, error in
            guard let self else { return }

            if let error {
                self.respond(connection: connection, response: .text(status: 500, body: error.localizedDescription))
                return
            }

            var nextBuffer = buffer
            if let data {
                nextBuffer.append(data)
            }

            if let request = HTTPRequest.parse(nextBuffer) {
                self.handle(request: request, connection: connection)
                return
            }

            if isComplete {
                self.respond(connection: connection, response: .text(status: 400, body: "Requete invalide"))
                return
            }

            self.receive(connection: connection, buffer: nextBuffer)
        }
    }

    private func handle(request: HTTPRequest, connection: NWConnection) {
        switch (request.method, request.path) {
        case ("OPTIONS", _):
            respond(connection: connection, response: .empty(status: 204))
        case ("GET", "/status"):
            respond(connection: connection, response: .json(status: 200, value: statusSnapshot()))
        case ("POST", "/command"):
            do {
                let command = try JSONDecoder().decode(CommandRequest.self, from: request.body)
                let result = registry.execute(command, context: makeActionContext())
                respond(connection: connection, response: .json(status: 200, value: result))
            } catch {
                respond(connection: connection, response: .text(status: 400, body: "Commande invalide: \(error)"))
            }
        default:
            respond(connection: connection, response: .text(status: 404, body: "Route inconnue"))
        }
    }

    private func respond(connection: NWConnection, response: HTTPResponse) {
        connection.send(content: response.data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func statusSnapshot() -> StatusSnapshot {
        StatusSnapshot(
            daemonName: "glassdeck-mac-daemon",
            version: "0.1.0",
            uptimeSeconds: UInt64(Date().timeIntervalSince(startedAt)),
            connectedClients: connectedClients,
            availableActions: registry.descriptors
        )
    }

    private func makeActionContext() -> ActionContext {
        ActionContext(
            actionCount: registry.actions.count,
            connectedClients: connectedClients
        )
    }
}

struct HTTPRequest {
    let method: String
    let path: String
    let body: Data

    static func parse(_ data: Data) -> Self? {
        guard let separatorRange = data.range(of: Data("\r\n\r\n".utf8)) else {
            return nil
        }

        let headerData = data[..<separatorRange.lowerBound]
        guard let headers = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let headerLines = headers.split(separator: "\r\n", omittingEmptySubsequences: false).map(String.init)
        guard let requestLine = headerLines.first else {
            return nil
        }

        let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else {
            return nil
        }

        let contentLength = headerLines
            .compactMap { line -> Int? in
                let pair = line.split(separator: ":", maxSplits: 1).map(String.init)
                guard pair.count == 2, pair[0].caseInsensitiveCompare("Content-Length") == .orderedSame else {
                    return nil
                }
                return Int(pair[1].trimmingCharacters(in: .whitespaces))
            }
            .first ?? 0

        let bodyStart = separatorRange.upperBound
        let availableBodyBytes = data.distance(from: bodyStart, to: data.endIndex)
        guard availableBodyBytes >= contentLength else {
            return nil
        }

        let bodyEnd = data.index(bodyStart, offsetBy: contentLength)
        return Self(
            method: parts[0],
            path: parts[1],
            body: Data(data[bodyStart..<bodyEnd])
        )
    }
}

struct HTTPResponse {
    let status: Int
    let contentType: String
    let body: Data

    static func empty(status: Int) -> Self {
        Self(status: status, contentType: "text/plain; charset=utf-8", body: Data())
    }

    static func text(status: Int, body: String) -> Self {
        Self(status: status, contentType: "text/plain; charset=utf-8", body: Data(body.utf8))
    }

    static func json<T: Encodable>(status: Int, value: T) -> Self {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return Self(
                status: status,
                contentType: "application/json; charset=utf-8",
                body: try encoder.encode(value)
            )
        } catch {
            return .text(status: 500, body: "JSON encode error: \(error)")
        }
    }

    var data: Data {
        var response = Data()
        response.append(
            """
            HTTP/1.1 \(status) \(statusText)\r
            Content-Type: \(contentType)\r
            Content-Length: \(body.count)\r
            Access-Control-Allow-Origin: *\r
            Access-Control-Allow-Methods: GET, POST, OPTIONS\r
            Access-Control-Allow-Headers: Content-Type\r
            Connection: close\r
            \r

            """.data(using: .utf8)!
        )
        response.append(body)
        return response
    }

    private var statusText: String {
        switch status {
        case 200: "OK"
        case 204: "No Content"
        case 400: "Bad Request"
        case 404: "Not Found"
        case 500: "Internal Server Error"
        default: "OK"
        }
    }
}

struct ActionRegistry {
    let actions: [String: Action]

    init() {
        let registeredActions = [
            Action(
                descriptor: ActionDescriptor(id: "ping", label: "Tester la connexion", kind: .system),
                handler: .ping
            ),
            Action(
                descriptor: ActionDescriptor(id: "status", label: "Lire l'etat du daemon", kind: .system),
                handler: .status
            ),
            Action(
                descriptor: ActionDescriptor(id: "open-url", label: "Ouvrir une URL", kind: .application),
                handler: .openURL
            ),
            Action(
                descriptor: ActionDescriptor(id: "open-applications", label: "Ouvrir Applications", kind: .application),
                handler: .runCommand(program: "open", arguments: ["/Applications"])
            ),
        ]

        actions = Dictionary(uniqueKeysWithValues: registeredActions.map { ($0.descriptor.id, $0) })
    }

    var descriptors: [ActionDescriptor] {
        actions.values.map(\.descriptor).sorted { $0.id < $1.id }
    }

    func execute(_ request: CommandRequest, context: ActionContext) -> CommandResult {
        guard let action = actions[request.actionId] else {
            return CommandResult(
                requestId: request.requestId,
                actionId: request.actionId,
                success: false,
                message: "Action inconnue"
            )
        }

        let output = action.handler.execute(payload: request.payload, context: context)
        return CommandResult(
            requestId: request.requestId,
            actionId: request.actionId,
            success: output.success,
            message: output.message
        )
    }
}

struct Action {
    let descriptor: ActionDescriptor
    let handler: ActionHandler
}

enum ActionHandler {
    case ping
    case status
    case openURL
    case runCommand(program: String, arguments: [String])

    func execute(payload: JSONValue, context: ActionContext) -> ActionOutput {
        switch self {
        case .ping:
            return .success("pong")
        case .status:
            return .success("\(context.actionCount) action(s), \(context.connectedClients) client(s)")
        case .openURL:
            guard case .object(let object) = payload,
                  case .string(let url)? = object["url"]
            else {
                return .failure("Payload attendu: {\"url\":\"https://...\"}")
            }

            guard url.hasPrefix("https://") || url.hasPrefix("http://") else {
                return .failure("Seules les URL http et https sont acceptees")
            }

            return run(program: "open", arguments: [url])
        case .runCommand(let program, let arguments):
            return run(program: program, arguments: arguments)
        }
    }

    private func run(program: String, arguments: [String]) -> ActionOutput {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [program] + arguments

        let errorPipe = Pipe()
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                return .success("Commande executee: \(program)")
            }

            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .failure(errorMessage?.isEmpty == false ? errorMessage! : "Commande echouee: \(program)")
        } catch {
            return .failure("\(program): \(error.localizedDescription)")
        }
    }
}

struct ActionContext {
    let actionCount: Int
    let connectedClients: Int
}

struct ActionOutput {
    let success: Bool
    let message: String

    static func success(_ message: String) -> Self {
        Self(success: true, message: message)
    }

    static func failure(_ message: String) -> Self {
        Self(success: false, message: message)
    }
}

struct StatusSnapshot: Encodable {
    let daemonName: String
    let version: String
    let uptimeSeconds: UInt64
    let connectedClients: Int
    let availableActions: [ActionDescriptor]
}

struct ActionDescriptor: Encodable {
    let id: String
    let label: String
    let kind: ActionKind
}

enum ActionKind: String, Encodable {
    case system
    case application
    case script
}

struct CommandRequest: Decodable {
    let requestId: String
    let actionId: String
    let payload: JSONValue

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case actionId = "action_id"
        case payload
    }
}

struct CommandResult: Encodable {
    let requestId: String
    let actionId: String
    let success: Bool
    let message: String
}

enum JSONValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
