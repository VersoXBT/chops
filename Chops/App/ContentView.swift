import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Skill.name) private var skills: [Skill]
    @State private var scanner: SkillScanner?
    @State private var fileWatcher: FileWatcher?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var catalogService = CatalogService()

    var body: some View {
        @Bindable var appState = appState

        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(catalog: catalogService)
        } content: {
            if case .catalogCategory(let category) = appState.sidebarFilter {
                CatalogListView(catalog: catalogService, category: category)
            } else {
                SkillListView()
            }
        } detail: {
            if case .catalogCategory = appState.sidebarFilter,
               let catalogItem = appState.selectedCatalogItem {
                CatalogDetailView(selection: catalogItem)
            } else if let skill = appState.selectedSkill {
                SkillDetailView(skill: skill)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "doc.text",
                    description: Text("Choose an item from the sidebar to view it.")
                )
            }
        }
        .searchable(text: $appState.searchText, prompt: "Search skills...")
        .onAppear {
            startScanning()
        }
        .sheet(isPresented: $appState.showingNewSkillSheet) {
            NewSkillSheet()
        }
        .sheet(isPresented: $appState.showingRegistrySheet) {
            RegistrySheet()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        appState.showingNewSkillSheet = true
                    } label: {
                        Label("New Skill", systemImage: "plus")
                    }
                    Button {
                        appState.showingRegistrySheet = true
                    } label: {
                        Label("Browse Registry", systemImage: "globe")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .menuIndicator(.hidden)
            }
        }
        .frame(minWidth: 900, minHeight: 500)
        .onReceive(NotificationCenter.default.publisher(for: .customScanPathsChanged)) { _ in
            scanner?.scanAll()
        }
    }

    private func startScanning() {
        AppLogger.ui.notice("App started, beginning initial scan")
        let scanner = SkillScanner(modelContext: modelContext)
        self.scanner = scanner
        scanner.removeDeletedSkills()
        scanner.scanAll()
        catalogService.scanAll()

        var allPaths: [String] = []
        for tool in ToolSource.allCases {
            allPaths.append(contentsOf: tool.globalPaths)
        }

        let catalogRef = catalogService
        let watcher = FileWatcher { _ in
            scanner.scanAll()
            scanner.removeDeletedSkills()
            catalogRef.scanAll()
        }
        watcher.watchDirectories(allPaths)
        self.fileWatcher = watcher
        AppLogger.ui.notice("File watchers active on \(allPaths.count) directories")

        // Sync remote servers in the background
        Task {
            await scanner.syncAllRemoteServers()
        }
    }
}
