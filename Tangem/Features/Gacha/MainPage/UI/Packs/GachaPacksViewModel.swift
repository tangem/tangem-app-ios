//
//  GachaPacksViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class GachaPacksViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any GachaPacksProvider

    private var loreID: String?
    private var reloadTask: Task<Void, Never>?

    // MARK: - Publishers

    @Published private(set) var state: State = .idle

    // MARK: - Init

    init(provider: any GachaPacksProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    @MainActor
    func load() async {
        switch state {
        case .loading, .content, .empty:
            return
        case .idle, .failed:
            reload()
        }
    }

    func reload(loreID: String?) {
        self.loreID = loreID
        reload()
    }

    func reload() {
        reloadTask?.cancel()
        reloadTask = runTask(in: self) { @MainActor viewModel in
            await viewModel.loadPacks()
        }
    }
}

// MARK: - State

extension GachaPacksViewModel {
    enum State {
        case idle
        case loading
        case content([GachaPackCard.Model])
        case empty
        case failed
    }
}

// MARK: - Private logic

private extension GachaPacksViewModel {
    /// Every load runs through `reloadTask`, so `Task.isCancelled` is the staleness check:
    /// each `reload()` cancels the predecessor, and only the latest task is left uncancelled to write state.
    @MainActor
    func loadPacks() async {
        guard !Task.isCancelled else { return }

        state = .loading

        do {
            let packs = try await provider.load(loreID: loreID)
            try Task.checkCancellation()

            state = packs.isEmpty ? .empty : .content(Mapper.map(packs))
        } catch {
            guard !Task.isCancelled else { return }

            state = .failed
        }
    }
}
