//
//  CollectiblesPrizePoolViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
final class CollectiblesPrizePoolViewModel: ObservableObject {
    // MARK: - Properties

    private let machineID: String
    private let provider: any CollectiblesPrizePoolProvider

    private var prizes: [CollectiblesPrize] = []
    private var nextPage: Int?
    private var loadingTask: Task<Void, Error>?

    // MARK: - Publishers

    @Published private(set) var state: State = .loading
    @Published private(set) var paginationState: PaginationState = .none

    // MARK: - Init

    init(machineID: String, provider: any CollectiblesPrizePoolProvider) {
        self.machineID = machineID
        self.provider = provider
    }

    deinit {
        loadingTask?.cancel()
    }

    // MARK: - Methods

    func load() {
        guard case .loading = state, loadingTask == nil else { return }

        fetch(page: Constants.firstPage)
    }

    func retry() {
        guard case .failed = state else { return }

        state = .loading
        fetch(page: Constants.firstPage)
    }

    func loadMore() {
        guard let nextPage, paginationState.allowsLoadingMore else { return }

        paginationState = .loading
        fetch(page: nextPage)
    }
}

// MARK: - State

extension CollectiblesPrizePoolViewModel {
    enum State {
        case loading
        case content([CollectiblesPrizeCard.Model])
        case empty
        case failed
    }

    enum PaginationState {
        case none
        case ready
        case loading
        case failed

        var allowsLoadingMore: Bool {
            switch self {
            case .ready, .failed: true
            case .none, .loading: false
            }
        }
    }
}

// MARK: - Private logic

private extension CollectiblesPrizePoolViewModel {
    func fetch(page: Int) {
        loadingTask = runTask(in: self) { @MainActor viewModel in
            do {
                let loaded = try await viewModel.provider.load(machineID: viewModel.machineID, page: page)
                try Task.checkCancellation()
                viewModel.loadingTask = nil
                viewModel.apply(loaded, requestedPage: page)
            } catch is CancellationError {
                return
            } catch {
                viewModel.loadingTask = nil
                viewModel.fail()
            }
        }
    }

    /// The pool is live, cards get won and restocked between requests, so a page can repeat what the previous one
    /// carried. The next page counts from the one asked for rather than the one echoed back.
    func apply(_ loaded: CollectiblesPrizePoolPage, requestedPage: Int) {
        let isFirstPage = requestedPage == Constants.firstPage
        let knownIDs: Set<CollectiblesPrize.ID> = isFirstPage ? [] : Set(prizes.map(\.id))
        let newPrizes = loaded.prizes.filter { !knownIDs.contains($0.id) }

        prizes = isFirstPage ? newPrizes : prizes + newPrizes
        nextPage = loaded.hasNext ? requestedPage + 1 : nil

        if newPrizes.isEmpty, let nextPage {
            fetch(page: nextPage)
            return
        }

        paginationState = loaded.hasNext ? .ready : .none
        state = prizes.isEmpty ? .empty : .content(prizes.map(Mapper.map))
    }

    func fail() {
        if case .loading = state {
            state = .failed
        } else {
            paginationState = .failed
        }
    }

    enum Constants {
        static let firstPage = 1
    }
}
