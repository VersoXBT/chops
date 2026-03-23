import SwiftUI

struct CatalogListView: View {
    @Environment(AppState.self) private var appState
    let catalog: CatalogService
    let category: CatalogCategory

    private var title: String { category.displayName }

    var body: some View {
        @Bindable var appState = appState

        List(selection: $appState.selectedCatalogItem) {
            switch category {
            case .plugin:
                ForEach(filteredPlugins) { plugin in
                    PluginRow(plugin: plugin)
                        .tag(CatalogSelection.plugin(plugin))
                }
            case .agent:
                ForEach(filteredAgents) { agent in
                    AgentRow(agent: agent)
                        .tag(CatalogSelection.agent(agent))
                }
            case .mcpServer:
                ForEach(filteredMCPServers) { server in
                    MCPServerRow(server: server)
                        .tag(CatalogSelection.mcpServer(server))
                }
            }
        }
        .navigationTitle(title)
        .overlay {
            if isEmpty {
                ContentUnavailableView(
                    "No \(category.displayName)",
                    systemImage: category.iconName,
                    description: Text("No \(category.displayName.lowercased()) found.")
                )
            }
        }
    }

    private var isEmpty: Bool {
        switch category {
        case .plugin: filteredPlugins.isEmpty
        case .agent: filteredAgents.isEmpty
        case .mcpServer: filteredMCPServers.isEmpty
        }
    }

    private var filteredPlugins: [PluginEntry] {
        let items = catalog.plugins
        guard !appState.searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(appState.searchText) ||
            $0.marketplace.localizedCaseInsensitiveContains(appState.searchText)
        }
    }

    private var filteredAgents: [AgentEntry] {
        let items = catalog.agents
        guard !appState.searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(appState.searchText) ||
            $0.agentDescription.localizedCaseInsensitiveContains(appState.searchText)
        }
    }

    private var filteredMCPServers: [MCPServerEntry] {
        let items = catalog.mcpServers
        guard !appState.searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(appState.searchText) ||
            $0.serverDescription.localizedCaseInsensitiveContains(appState.searchText) ||
            $0.source.localizedCaseInsensitiveContains(appState.searchText)
        }
    }
}

// MARK: - Row Views

private struct PluginRow: View {
    let plugin: PluginEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.extension")
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(plugin.name)
                    .lineLimit(1)
                Text(plugin.marketplace)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("v\(plugin.version)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            ScopeBadge(scope: plugin.scope)
        }
        .padding(.vertical, 4)
    }
}

private struct AgentRow: View {
    let agent: AgentEntry

    var body: some View {
        HStack(spacing: 8) {
            Text(agent.emoji.isEmpty ? "🤖" : agent.emoji)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(agent.name)
                    .lineLimit(1)
                if !agent.agentDescription.isEmpty {
                    Text(agent.agentDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            if !agent.color.isEmpty {
                Circle()
                    .fill(colorFromName(agent.color))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": .red
        case "blue": .blue
        case "green": .green
        case "orange": .orange
        case "purple": .purple
        case "yellow": .yellow
        case "pink": .pink
        case "teal": .teal
        case "cyan": .cyan
        case "indigo": .indigo
        case "mint": .mint
        default: .gray
        }
    }
}

private struct MCPServerRow: View {
    let server: MCPServerEntry

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "server.rack")
                .foregroundStyle(.green)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.name)
                    .lineLimit(1)
                if !server.serverDescription.isEmpty {
                    Text(server.serverDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(server.source)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

private struct ScopeBadge: View {
    let scope: String

    var body: some View {
        Text(scope)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .foregroundStyle(scope == "user" ? .blue : .orange)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                (scope == "user" ? Color.blue : Color.orange).opacity(0.12),
                in: RoundedRectangle(cornerRadius: 3)
            )
    }
}
