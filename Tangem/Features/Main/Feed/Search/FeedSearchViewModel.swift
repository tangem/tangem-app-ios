//
//  FeedSearchViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

final class FeedSearchViewModel: ObservableObject {
    @Published private(set) var isActive = false

    let searchBarViewModel: FeedSearchBarViewModel
    let tabsViewModel: FeedSearchTabsViewModel

    private let resultsQuery: CurrentValueSubject<String, Never>

    private var bag = Set<AnyCancellable>()

    init(
        searchBarViewModel: FeedSearchBarViewModel,
        resultsQuery: CurrentValueSubject<String, Never>,
        tabsViewModel: FeedSearchTabsViewModel
    ) {
        self.searchBarViewModel = searchBarViewModel
        self.resultsQuery = resultsQuery
        self.tabsViewModel = tabsViewModel

        bind()
    }

    deinit {
        AppLogger.debug("FeedSearchViewModel deinit")
    }

    func close() {
        isActive = false
        syncVisibility()
        searchBarViewModel.query = ""
        resultsQuery.send("")
    }

    func reset() {
        searchBarViewModel.endEditing()
        close()
    }
}

// MARK: - Binding

private extension FeedSearchViewModel {
    func bind() {
        searchBarViewModel
            .queryPublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, query in
                let isBlank = query.trimmed().isEmpty
                guard viewModel.isActive || !isBlank else { return }

                viewModel.resultsQuery.send(query)
                viewModel.onQueryBlankChange(isBlank)
            }
            .store(in: &bag)
    }
}

// MARK: - State

private extension FeedSearchViewModel {
    func onQueryBlankChange(_ isBlank: Bool) {
        guard isBlank == isActive else {
            return
        }

        isActive = !isBlank
        syncVisibility()
    }

    func syncVisibility() {
        tabsViewModel.setSearching(isActive)
    }
}
