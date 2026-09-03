//
//  GachaPacksViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

@MainActor
final class GachaPacksViewModel: ObservableObject {
    // MARK: - Properties

    private let provider: any GachaPacksProvider

    private var loreID: String?
    private var query = ""
    private var reloadTask: Task<Void, Error>?
    private var cache: [String?: State] = [:]

    /// Drives the empty and failed copy: the wording differs once a query is what produced the result.
    private var hasQuery: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty
    }

    // MARK: - Publishers

    @Published private(set) var state: State = .idle

    // MARK: - Init

    init(provider: any GachaPacksProvider) {
        self.provider = provider
    }

    // MARK: - Methods

    func load() async {
        switch state {
        case .loading, .content, .empty:
            return
        case .idle, .failed:
            reload()
        }
    }

    func reload(loreID: String?) {
        cacheCurrentState()
        self.loreID = loreID

        if let cached = cache[loreID] {
            reloadTask?.cancel()
            state = cached
            return
        }

        state = .loading
        reload()
    }

    func reset() {
        apply(.idle)
    }

    func reset(loreID: String?) {
        self.loreID = loreID
        reset()
    }

    func showContent(_ models: [GachaPackCard.Model]) {
        apply(.content(models))
    }

    func showEmpty() {
        apply(.empty(hasQuery: false))
    }

    func showLoading() {
        apply(.loading)
    }

    func cancelLoading() {
        reloadTask?.cancel()
        if state.isLoading {
            state = .idle
        }
    }

    /// Typing is debounced; clearing reloads the unfiltered list right away.
    func search(query: String) {
        self.query = query

        guard !hasQuery else {
            reload(debounced: true)
            return
        }

        state = .loading
        reload()
    }

    func reload() {
        reload(debounced: false)
    }
}

// MARK: - State

extension GachaPacksViewModel {
    enum State {
        case idle
        case loading
        case content([GachaPackCard.Model])
        case empty(hasQuery: Bool)
        case failed(hasQuery: Bool)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        var isContentLoaded: Bool {
            if case .content = self {
                return true
            }
            return false
        }
    }
}

private extension GachaPacksViewModel {
    // MARK: - Private logic

    func apply(_ state: State) {
        reloadTask?.cancel()
        query = ""
        self.state = state
    }

    func cacheCurrentState() {
        switch state {
        case .content, .empty:
            cache[loreID] = state
        case .idle, .loading, .failed:
            break
        }
    }

    /// Every load runs through `reloadTask`, so `Task.isCancelled` is the staleness check:
    /// each reload cancels the predecessor, and only the latest task is left uncancelled to write state.
    func reload(debounced: Bool) {
        reloadTask?.cancel()
        reloadTask = runTask(in: self) { @MainActor viewModel in
            if debounced {
                try await Task.sleep(for: Constants.searchDebounce)
            }

            await viewModel.fetch()
        }
    }

    func fetch() async {
        guard !Task.isCancelled else { return }

        if !state.isContentLoaded {
            state = .loading
        }

        do {
            let packs = try await provider.load(loreID: loreID, query: query)
            try Task.checkCancellation()

            let models = Mapper.map(packs)
            state = packs.isEmpty ? .empty(hasQuery: hasQuery) : .content(models)

            if !hasQuery {
                cache[loreID] = state
            }
        } catch {
            guard !Task.isCancelled else { return }

            state = .failed(hasQuery: hasQuery)
        }
    }

    enum Constants {
        static let searchDebounce: Duration = .milliseconds(300)
    }
}
