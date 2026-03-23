import SwiftUI
import MarkdownUI

struct CatalogDetailView: View {
    let selection: CatalogSelection

    var body: some View {
        switch selection {
        case .plugin(let plugin):
            PluginDetailView(plugin: plugin)
        case .agent(let agent):
            AgentDetailView(agent: agent)
        case .mcpServer(let server):
            MCPServerDetailView(server: server)
        }
    }
}

// MARK: - Plugin Detail

private struct PluginDetailView: View {
    let plugin: PluginEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.title)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plugin.name)
                            .font(.title2.bold())
                        Text(plugin.marketplace)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                DetailRow(label: "Version", value: plugin.version)
                DetailRow(label: "Scope", value: plugin.scope)
                DetailRow(label: "Install Path", value: plugin.installPath, monospaced: true)

                if let date = plugin.installedAt {
                    DetailRow(label: "Installed", value: date.formatted(date: .abbreviated, time: .shortened))
                }
                if let date = plugin.lastUpdated {
                    DetailRow(label: "Last Updated", value: date.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .padding()
        }
        .navigationTitle(plugin.name)
        .toolbar {
            ToolbarItem {
                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: plugin.installPath)
                } label: {
                    Image(systemName: "folder")
                }
                .help("Show in Finder")
            }
        }
    }
}

// MARK: - Agent Detail

private struct AgentDetailView: View {
    let agent: AgentEntry

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        Text(agent.emoji.isEmpty ? "🤖" : agent.emoji)
                            .font(.title)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(agent.name)
                                .font(.title2.bold())
                            if !agent.agentDescription.isEmpty {
                                Text(agent.agentDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !agent.vibe.isEmpty {
                        Text(agent.vibe)
                            .font(.callout)
                            .italic()
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Markdown(strippedContent)
                        .markdownCodeSyntaxHighlighter(HighlightrSyntaxHighlighter())
                        .textSelection(.enabled)
                }
                .padding()
            }

            Divider()

            HStack(spacing: 12) {
                if !agent.color.isEmpty {
                    Label(agent.color.capitalized, systemImage: "paintpalette")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(agent.filePath)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .navigationTitle(agent.name)
        .toolbar {
            ToolbarItem {
                Button {
                    NSWorkspace.shared.selectFile(agent.filePath, inFileViewerRootedAtPath: "")
                } label: {
                    Image(systemName: "folder")
                }
                .help("Show in Finder")
            }
        }
    }

    private var strippedContent: String {
        FrontmatterParser.parse(agent.content).content
    }
}

// MARK: - MCP Server Detail

private struct MCPServerDetailView: View {
    let server: MCPServerEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.title)
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.name)
                            .font(.title2.bold())
                        if !server.serverDescription.isEmpty {
                            Text(server.serverDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                DetailRow(label: "Source Plugin", value: server.source)

                if let command = server.command {
                    DetailRow(label: "Command", value: command, monospaced: true)
                }
                if !server.args.isEmpty {
                    DetailRow(label: "Args", value: server.args.joined(separator: " "), monospaced: true)
                }
                if let url = server.url {
                    DetailRow(label: "URL", value: url, monospaced: true)
                }
            }
            .padding()
        }
        .navigationTitle(server.name)
    }
}

// MARK: - Shared Components

private struct DetailRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            if monospaced {
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            } else {
                Text(value)
                    .textSelection(.enabled)
            }
        }
    }
}
