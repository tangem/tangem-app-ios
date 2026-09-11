//
//  GachaAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

final class GachaAccountViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any GachaAccountSummaryProvider

    // MARK: - Publishers

    @Published private(set) var state: State = .idle

    // MARK: - Init

    init(provider: any GachaAccountSummaryProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    @MainActor
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

extension GachaAccountViewModel {
    enum State {
        case idle
        case loading
        case content(GachaAccountView.Summary)
        case failed
    }
}

// MARK: - Private logic

private extension GachaAccountViewModel {
    @MainActor
    func loadSummary() async {
        state = .loading

        do {
            let summary = try await provider.load()
            try Task.checkCancellation()
            state = .content(GachaAccountMapper.map(summary))
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed
        }
    }
}
