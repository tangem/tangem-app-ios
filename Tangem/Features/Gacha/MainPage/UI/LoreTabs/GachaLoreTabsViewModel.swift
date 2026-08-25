//
//  GachaLoreTabsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class GachaLoreTabsViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any GachaLoresProvider

    // MARK: - Publishers

    @Published var selectedTab: GachaLoreTabsView.LoreTab = GachaLoreTabsMapper.allTab
    @Published private(set) var state: State = .idle

    // MARK: - Init

    init(provider: any GachaLoresProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    @MainActor
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

extension GachaLoreTabsViewModel {
    enum State {
        case idle
        case loading
        case content([GachaLoreTabsView.LoreTab])
        case empty
        case failed
    }
}

// MARK: - Private logic

private extension GachaLoreTabsViewModel {
    @MainActor
    func loadTabs() async {
        state = .loading

        do {
            let lores = try await provider.load()
            try Task.checkCancellation()

            guard !lores.isEmpty else {
                state = .empty
                return
            }

            let tabs = GachaLoreTabsMapper.map(lores)
            selectedTab = tabs.first { $0.id == selectedTab.id } ?? GachaLoreTabsMapper.allTab
            state = .content(tabs)
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
