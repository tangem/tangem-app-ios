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
    private var paginationTask: Task<Void, Never>?

    // MARK: - Publishers

    @Published private(set) var state: State = .idle
    @Published private(set) var paginationState: PaginationState = .none
    @Published private(set) var loreID: String?

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
        case .loading, .content, .empty, .reloading:
            return
        case .idle, .failed:
            reload()
        }
    }

    func reload() {
        reload(debounced: false)
    }

    func refresh() async {
        reload()

        _ = await reloadTask?.result
    }

    func reload(loreID: String?) {
        cancelTasks()
        self.loreID = loreID

        guard let catalogue = model.switchLore(loreID) else {
            switch state {
            case .content(let models):
                state = .reloading(.content(models))
            case .empty(let hasQuery):
                state = .reloading(.empty(hasQuery: hasQuery))
            case .reloading:
                break
            case .idle, .loading, .failed:
                state = .loading
            }

            return reload()
        }

        apply(catalogue)
    }

    func loadMore() {
        guard state.isContentLoaded, paginationState.allowsLoadingMore else { return }

        paginationState = .loading
        paginationTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let catalogue = try await model.loadMore()
                apply(catalogue)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }

                paginationState = .failed
            }
        }
    }

    func reset(loreID: String?) {
        cancelTasks()
        self.loreID = loreID
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

        switch state {
        case .loading:
            state = .idle
        case .reloading(let shown):
            state = shown.state
        case .idle, .content, .empty, .failed:
            break
        }
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
        case reloading(Shown)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

        var isReloading: Bool {
            if case .reloading = self {
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

    enum Shown {
        case content([CollectiblesPackCard.Model])
        case empty(hasQuery: Bool)

        var state: State {
            switch self {
            case .content(let models): .content(models)
            case .empty(let hasQuery): .empty(hasQuery: hasQuery)
            }
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
        reloadTask = Task { @MainActor [weak self] in
            if debounced {
                try await Task.sleep(for: Constants.searchDebounce)
            }

            await self?.fetch()
        }
    }

    func fetch() async {
        guard !Task.isCancelled else { return }

        switch state {
        case .content, .empty, .reloading:
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
