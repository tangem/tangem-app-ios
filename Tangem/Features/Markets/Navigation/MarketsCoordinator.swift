//
//  MarketsCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit

class MarketsCoordinator: CoordinatorObject {
    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Root Published

    @Published private(set) var marketsViewModel: MarketsViewModel?
    @Published private(set) var marketsMainViewModel: MarketsMainViewModel?

    // MARK: - Coordinators

    @Published var tokenDetailsCoordinator: MarketsTokenDetailsCoordinator?
    @Published var marketsSearchCoordinator: MarketsSearchCoordinator?
    @Published var newsListCoordinator: NewsListCoordinator?
    @Published var newsPagerViewModel: NewsPagerViewModel?
    @Published var newsPagerTokenDetailsCoordinator: MarketsTokenDetailsCoordinator?

    // MARK: - Child ViewModels

    @Published var marketsListOrderBottomSheetViewModel: MarketsListOrderBottomSheetViewModel?

    // MARK: - Private Properties

    private lazy var quotesRepositoryUpdateHelper: MarketsQuotesUpdateHelper = CommonMarketsQuotesUpdateHelper()

    // MARK: - Init

    required init(dismissAction: @escaping Action<Void>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    deinit {
        AppLogger.debug("MarketsCoordinator deinit")
    }

    // MARK: - Implementation

    func start(with options: MarketsCoordinator.Options) {
        let quotesRepositoryUpdateHelper = CommonMarketsQuotesUpdateHelper()

        if FeatureProvider.isAvailable(.marketsAndNews) {
            let viewModel = MarketsMainViewModel(
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
                coordinator: self
            )

            marketsMainViewModel = viewModel
        } else {
            let viewModel = MarketsViewModel(
                quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper,
                coordinator: self
            )

            marketsViewModel = viewModel
        }
    }
}

extension MarketsCoordinator {
    struct Options {}
}

extension MarketsCoordinator: MarketsRoutable {
    func openFilterOrderBottonSheet(with provider: MarketsListDataFilterProvider) {
        marketsListOrderBottomSheetViewModel = .init(from: provider, onDismiss: { [weak self] in
            self?.marketsListOrderBottomSheetViewModel = nil
        })
    }

    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        let tokenDetailsCoordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.tokenDetailsCoordinator = nil
            }
        )
        tokenDetailsCoordinator.start(
            with: .init(info: tokenInfo, style: .marketsSheet)
        )

        self.tokenDetailsCoordinator = tokenDetailsCoordinator
    }
}

// MARK: - MarketsMainRoutable

extension MarketsCoordinator: MarketsMainRoutable {
    func openSeeAll(with widgetType: MarketsWidgetType) {
        switch widgetType {
        case .market, .pulse:
            let marketsSearchCoordinator = MarketsSearchCoordinator(
                dismissAction: { [weak self] in
                    self?.marketsSearchCoordinator = nil
                }
            )

            marketsSearchCoordinator.start(with: .init(quotesRepositoryUpdateHelper: quotesRepositoryUpdateHelper))

            self.marketsSearchCoordinator = marketsSearchCoordinator
        case .news:
            openNewsList()
        case .earn:
            // [REDACTED_TODO_COMMENT]
            break
        }
    }

    func openNewsDetails(newsIds: [Int], selectedIndex: Int) {
        let viewModel = NewsPagerViewModel(
            newsIds: newsIds,
            initialIndex: selectedIndex,
            dateFormatter: NewsDateFormatter(),
            coordinator: self
        )
        newsPagerViewModel = viewModel
    }

    func openNewsList() {
        let coordinator = NewsListCoordinator(
            dismissAction: { [weak self] in
                self?.newsListCoordinator = nil
            }
        )

        coordinator.start(with: .init())

        newsListCoordinator = coordinator
    }
}

// MARK: - NewsDetailsRoutable (for widget pager)

extension MarketsCoordinator: NewsDetailsRoutable {
    var hasMoreNews: Bool { false }

    func dismissNewsDetails() {
        newsPagerViewModel = nil
    }

    func share(url: String) {
        guard let url = URL(string: url) else { return }
        AppPresenter.shared.show(UIActivityViewController(activityItems: [url], applicationActivities: nil))
    }

    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openTokenDetails(_ token: MarketsTokenModel) {
        let coordinator = MarketsTokenDetailsCoordinator(
            dismissAction: { [weak self] in
                self?.newsPagerTokenDetailsCoordinator = nil
            }
        )
        coordinator.start(with: .init(info: token, style: .marketsSheet))
        newsPagerTokenDetailsCoordinator = coordinator
    }

    func loadMoreNews() async -> [Int] {
        []
    }
}
