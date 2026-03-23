import Foundation

@Observable
final class CatalogService {
    private(set) var plugins: [PluginEntry] = []
    private(set) var agents: [AgentEntry] = []
    private(set) var mcpServers: [MCPServerEntry] = []

    private let fm = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser.path

    func scanAll() {
        scanPlugins()
        scanAgents()
        scanMCPServers()
    }

    // MARK: - Plugins

    private func scanPlugins() {
        let path = "\(home)/.claude/plugins/installed_plugins.json"
        guard let data = fm.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pluginsDict = json["plugins"] as? [String: [[String: Any]]] else {
            plugins = []
            return
        }

        var result: [PluginEntry] = []
        for (key, installs) in pluginsDict {
            let parts = key.split(separator: "@", maxSplits: 1)
            let pluginName = String(parts.first ?? Substring(key))
            let marketplace = parts.count > 1 ? String(parts[1]) : ""

            for install in installs {
                let entry = PluginEntry(
                    id: "\(key)-\(install["scope"] as? String ?? "")-\(install["projectPath"] as? String ?? "")",
                    name: pluginName,
                    marketplace: marketplace,
                    version: install["version"] as? String ?? "",
                    scope: install["scope"] as? String ?? "",
                    installPath: install["installPath"] as? String ?? "",
                    installedAt: parseISO8601(install["installedAt"] as? String),
                    lastUpdated: parseISO8601(install["lastUpdated"] as? String)
                )
                result.append(entry)
            }
        }

        plugins = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Agents

    private func scanAgents() {
        let agentsDir = "\(home)/.claude/agents"
        guard let contents = try? fm.contentsOfDirectory(atPath: agentsDir) else {
            agents = []
            return
        }

        var result: [AgentEntry] = []
        for file in contents where file.hasSuffix(".md") {
            let filePath = "\(agentsDir)/\(file)"
            guard let data = fm.contents(atPath: filePath),
                  let text = String(data: data, encoding: .utf8) else { continue }

            let parsed = FrontmatterParser.parse(text)
            let entry = AgentEntry(
                id: file,
                name: parsed.frontmatter["name"] ?? file.replacingOccurrences(of: ".md", with: ""),
                agentDescription: parsed.frontmatter["description"] ?? "",
                color: parsed.frontmatter["color"] ?? "",
                emoji: parsed.frontmatter["emoji"] ?? "",
                vibe: parsed.frontmatter["vibe"] ?? "",
                filePath: filePath,
                content: text
            )
            result.append(entry)
        }

        agents = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - MCP Servers

    private func scanMCPServers() {
        let cacheDir = "\(home)/.claude/plugins/cache"
        guard let marketplaces = try? fm.contentsOfDirectory(atPath: cacheDir) else {
            mcpServers = []
            return
        }

        var result: [MCPServerEntry] = []
        for marketplace in marketplaces {
            let marketplacePath = "\(cacheDir)/\(marketplace)"
            guard let plugins = try? fm.contentsOfDirectory(atPath: marketplacePath) else { continue }

            for plugin in plugins {
                let pluginPath = "\(marketplacePath)/\(plugin)"
                guard let versions = try? fm.contentsOfDirectory(atPath: pluginPath) else { continue }

                for version in versions {
                    let mcpPath = "\(pluginPath)/\(version)/mcp-configs/mcp-servers.json"
                    guard let data = fm.contents(atPath: mcpPath),
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let servers = json["mcpServers"] as? [String: [String: Any]] else { continue }

                    for (name, config) in servers {
                        let entry = MCPServerEntry(
                            id: "\(plugin)-\(name)",
                            name: name,
                            command: config["command"] as? String,
                            args: config["args"] as? [String] ?? [],
                            url: config["url"] as? String,
                            serverDescription: config["description"] as? String ?? "",
                            source: plugin
                        )
                        result.append(entry)
                    }
                }
            }
        }

        mcpServers = result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: - Helpers

    private func parseISO8601(_ string: String?) -> Date? {
        guard let string else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: string)
    }
}
