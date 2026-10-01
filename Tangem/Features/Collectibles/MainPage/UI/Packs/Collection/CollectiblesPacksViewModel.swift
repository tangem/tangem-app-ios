//
//  CollectiblesPacksViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

@MainActor
final class CollectiblesPacksViewModel: ObservableObject {
    // MARK: - Properties

    private let model: CollectiblesPacksModel
    private let packSelectionHandler: (CollectiblesPack) -> Void

    private var reloadTask: Task<Void, Error>?
    private var paginationTask: Task<Void, Error>?

    // MARK: - Publishers

    @Published private(set) var state: State = .idle
    @Published private(set) var paginationState: PaginationState = .none

    // MARK: - Init

    init(model: CollectiblesPacksModel, packSelectionHandler: @escaping (CollectiblesPack) -> Void) {
        self.model = model
        self.packSelectionHandler = packSelectionHandler
    }

    deinit {
        reloadTask?.cancel()
        paginationTask?.cancel()
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

    func reload() {
        reload(debounced: false)
    }

    func refresh() async {
        state = .loading
        reload()

        _ = await reloadTask?.result
    }

    func reload(loreID: String?) {
        cancelTasks()

        guard let catalogue = model.switchLore(loreID) else {
            state = .loading
            return reload()
        }

        apply(catalogue)
    }

    func loadMore() {
        guard state.isContentLoaded, paginationState.allowsLoadingMore else { return }

        paginationState = .loading
        paginationTask = runTask(in: self) { @MainActor viewModel in
            do {
                let catalogue = try await viewModel.model.loadMore()
                viewModel.apply(catalogue)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                viewModel.paginationState = .failed
            }
        }
    }

    func reset() {
        reset(loreID: nil)
    }

    func reset(loreID: String?) {
        cancelTasks()
        model.reset(loreID: loreID)
        state = .idle
        paginationState = .none
    }

    func show(_ snapshot: CollectiblesPacksModel.Snapshot) {
        cancelTasks()
        model.seed(snapshot)
        apply(model.catalogue())
    }

    func catalogueSnapshot() -> CollectiblesPacksModel.Snapshot {
        model.snapshot()
    }

    func showEmpty() {
        show(CollectiblesPacksModel.Snapshot(packs: [], cursor: nil, hasMore: false))
    }

    func showLoading() {
        cancelTasks()
        state = .loading
        paginationState = .none
    }

    func showFailed() {
        cancelTasks()
        state = .failed
        paginationState = .none
    }

    func cancelLoading() {
        cancelTasks()
        guard state.isLoading else { return }
        state = .idle
    }

    func selectPack(withID id: String) {
        guard let pack = model.pack(withID: id) else { return }

        packSelectionHandler(pack)
    }

    func search(query: String) {
        model.setQuery(query)

        guard model.hasQuery else {
            state = .loading
            return reload()
        }

        reload(debounced: true)
    }
}

// MARK: - State

extension CollectiblesPacksViewModel {
    enum State {
        case idle
        case loading
        case content([CollectiblesPackCard.Model])
        case empty(hasQuery: Bool)
        case failed

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

        var isFailed: Bool {
            if case .failed = self {
                return true
            }
            return false
        }
    }

    enum PaginationState {
        case none
        case ready
        case loading
        case failed

        var allowsLoadingMore: Bool {
            switch self {
            case .ready, .failed:
                return true
            case .none, .loading:
                return false
            }
        }
    }
}

// MARK: - Private logic

private extension CollectiblesPacksViewModel {
    /// Every load runs through `reloadTask`, so `Task.isCancelled` is the staleness check:
    /// each reload cancels the predecessor, and only the latest task is left uncancelled to write state.
    func reload(debounced: Bool) {
        cancelTasks()
        paginationState = .none
        reloadTask = runTask(in: self) { @MainActor viewModel in
            if debounced {
                try await Task.sleep(for: Constants.searchDebounce)
            }

            await viewModel.fetch()
        }
    }

    func fetch() async {
        guard !Task.isCancelled else { return }

        switch state {
        case .content, .empty:
            break
        case .idle, .loading, .failed:
            state = .loading
        }

        do {
            let catalogue = try await model.load()
            apply(catalogue)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }

            state = .failed
        }
    }

    func apply(_ catalogue: CollectiblesPacksModel.Catalogue) {
        state = catalogue.packs.isEmpty ? .empty(hasQuery: model.hasQuery) : .content(Mapper.map(catalogue.packs))
        paginationState = catalogue.hasMore ? .ready : .none
    }

    func cancelTasks() {
        reloadTask?.cancel()
        paginationTask?.cancel()
    }

    enum Constants {
        static let searchDebounce: Duration = .milliseconds(300)
    }
}
