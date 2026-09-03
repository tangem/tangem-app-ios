//
//  CollectiblesLoreTabsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class CollectiblesLoreTabsViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any CollectiblesLoresProvider

    // MARK: - Publishers

    @Published var selectedTab: CollectiblesLoreTabsView.LoreTab = CollectiblesLoreTabsMapper.allTab
    @Published private(set) var state: State = .idle

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
            await loadTabs()
        }
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
        state = .loading

        do {
            let lores = try await provider.load()
            try Task.checkCancellation()

            guard !lores.isEmpty else {
                state = .empty
                return
            }

            let tabs = CollectiblesLoreTabsMapper.map(lores)
            selectedTab = tabs.first { $0.id == selectedTab.id } ?? CollectiblesLoreTabsMapper.allTab
            state = .content(tabs)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
