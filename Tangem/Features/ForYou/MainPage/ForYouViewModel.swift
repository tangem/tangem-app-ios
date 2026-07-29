//
//  ForYouViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import Foundation

final class ForYouViewModel: ObservableObject {
    // MARK: - Properties

    let portfolioReviewViewModel: PortfolioReviewViewModel
    let earnOpportunitiesViewModel: EarnOpportunitiesViewModel
    let accountSelectorChipViewModel: ForYouAccountSelectorChipViewModel

    private var selectionNormalizationSubscription: AnyCancellable?

    // MARK: - Init

    init(
        coordinator: ForYouRoutable? = nil,
        selectedAccountsProvider: ForYouSelectedAccountsProvider
    ) {
        let selectionScopePublisher = Self.makeSelectionScopePublisher(selectedAccountsProvider: selectedAccountsProvider)

        portfolioReviewViewModel = .init(selectionScopePublisher: selectionScopePublisher, router: coordinator)
        earnOpportunitiesViewModel = .init(selectionScopePublisher: selectionScopePublisher, router: coordinator)
        accountSelectorChipViewModel = .init(
            selectionScopePublisher: selectionScopePublisher,
            resetSelectionAction: { selectedAccountsProvider.select(.all) },
            router: coordinator
        )

        bind(selectionScopePublisher: selectionScopePublisher, selectedAccountsProvider: selectedAccountsProvider)
    }
}

private extension ForYouViewModel {
    // MARK: - Private

    /// One resolver graph shared by the three VMs and the normalizer.
    static func makeSelectionScopePublisher(
        selectedAccountsProvider: ForYouSelectedAccountsProvider
    ) -> ForYouAccountSelectionResolver.SelectionScopePublisher {
        ForYouAccountSelectionResolver(selectionPublisher: selectedAccountsProvider.selectionPublisher)
            .selectionScopePublisher()
            .share(replay: 1)
            .eraseToAnyPublisher()
    }

    func bind(
        selectionScopePublisher: ForYouAccountSelectionResolver.SelectionScopePublisher,
        selectedAccountsProvider: ForYouSelectedAccountsProvider
    ) {
        // A redundant .subset re-arms when accounts appear later — dissolve it to .all; the re-emitted .all stops the loop.
        selectionNormalizationSubscription = selectionScopePublisher
            .receiveOnMain()
            .sink { scope in
                // Compare-and-set: a newer user write wins over this emission's decision.
                guard scope.isRedundantSubset, scope.selection == selectedAccountsProvider.selection else {
                    return
                }

                selectedAccountsProvider.select(.all)
            }
    }
}
