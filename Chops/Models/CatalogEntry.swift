import Foundation

struct PluginEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let marketplace: String
    let version: String
    let scope: String
    let installPath: String
    let installedAt: Date?
    let lastUpdated: Date?
}

struct AgentEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let agentDescription: String
    let color: String
    let emoji: String
    let vibe: String
    let filePath: String
    let content: String
}

struct MCPServerEntry: Identifiable, Hashable {
    let id: String
    let name: String
    let command: String?
    let args: [String]
    let url: String?
    let serverDescription: String
    let source: String
}

enum CatalogCategory: String, Hashable, CaseIterable, Identifiable {
    case plugin
    case agent
    case mcpServer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .plugin: "Plugins"
        case .agent: "Agents"
        case .mcpServer: "MCP Servers"
        }
    }

    var iconName: String {
        switch self {
        case .plugin: "puzzlepiece.extension"
        case .agent: "person.3"
        case .mcpServer: "server.rack"
        }
    }
}

enum CatalogSelection: Hashable {
    case plugin(PluginEntry)
    case agent(AgentEntry)
    case mcpServer(MCPServerEntry)
}
