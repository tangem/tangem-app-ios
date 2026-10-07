//
//  CollectiblesLoreTabsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

@MainActor
final class CollectiblesLoreTabsViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any CollectiblesLoresProvider

    private var loadTask: Task<Void, Never>?

    // MARK: - Publishers

    @Published var selectedTab: CollectiblesLoreTabsView.LoreTab = CollectiblesLoreTabsMapper.allTab
    @Published private(set) var state: State = .idle
    /// Everything the search can reach, whatever the selected tab is showing.
    @Published private(set) var totalPacksCount = 0

    // MARK: - Init

    init(provider: any CollectiblesLoresProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    func load() async {
        switch state {
        case .loading, .content, .empty:
            return
        case .idle, .failed:
            await refresh()
        }
    }

    func refresh() async {
        loadTask?.cancel()

        switch state {
        case .content, .empty:
            break
        case .idle, .loading, .failed:
            state = .loading
        }

        let task = runTask(in: self) { @MainActor viewModel in
            await viewModel.loadTabs()
        }
        loadTask = task

        await task.value
    }
}

// MARK: - State

extension CollectiblesLoreTabsViewModel {
    enum State {
        case idle
        case loading
        case content([CollectiblesLoreTabsView.LoreTab])
        case empty
        case failed
    }
}

// MARK: - Private logic

private extension CollectiblesLoreTabsViewModel {
    func loadTabs() async {
        do {
            let catalogue = try await provider.load()
            try Task.checkCancellation()

            totalPacksCount = catalogue.totalPacksCount

            guard !catalogue.lores.isEmpty else {
                state = .empty
                return
            }

            let tabs = CollectiblesLoreTabsMapper.map(catalogue)
            selectedTab = tabs.first { $0.id == selectedTab.id } ?? CollectiblesLoreTabsMapper.allTab
            state = .content(tabs)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            state = .failed
        }
    }
}
