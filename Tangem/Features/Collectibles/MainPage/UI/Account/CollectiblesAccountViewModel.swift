//
//  CollectiblesAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

@MainActor
final class CollectiblesAccountViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any CollectiblesAccountSummaryProvider

    // MARK: - Publishers

    @Published private(set) var state: State = .idle

    // MARK: - Init

    init(provider: any CollectiblesAccountSummaryProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    func load() async {
        switch state {
        case .loading, .content:
            return
        case .idle, .failed:
            await loadSummary()
        }
    }
}

// MARK: - State

extension CollectiblesAccountViewModel {
    enum State {
        case idle
        case loading
        case content(CollectiblesAccountView.Summary)
        case failed
    }
}

// MARK: - Private logic

private extension CollectiblesAccountViewModel {
    func loadSummary() async {
        state = .loading

        do {
            let summary = try await provider.load()
            try Task.checkCancellation()
            state = .content(CollectiblesAccountMapper.map(summary))
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
