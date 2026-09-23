//
//  RealAssetsFeedViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemUI

final class RealAssetsFeedViewModel: ObservableObject {
    @Published private(set) var shelfViewModel: RealAssetsWidgetViewModel?

    @Injected(\.marketsCategoriesProvider) private var categoriesProvider: MarketsCategoriesProvider

    let promoBanner: PromotionNotificationsViewModel

    private let router: any RealAssetsFeedRoutable
    private var sheetSize: ShtorkaSize = .collapsed
    private var requestedCategoryId: String?

    init(promotionNotificationsManager: PromotionNotificationsManager, router: any RealAssetsFeedRoutable) {
        promoBanner = PromotionNotificationsViewModel(promotionNotificationsManager: promotionNotificationsManager)
        self.router = router
    }

    deinit {
        AppLogger.debug("RealAssetsFeedViewModel deinit")
    }

    func onViewAppear() {
        guard shelfViewModel == nil else {
            return
        }

        let viewModel = RealAssetsWidgetViewModel(
            widgetType: .realAssets,
            categoriesProvider: categoriesProvider,
            widgetsUpdateHandler: nil,
            quotesRepositoryUpdateHelper: CommonMarketsQuotesUpdateHelper(),
            analyticsSection: .assets,
            coordinator: self
        )

        if sheetSize == .collapsed {
            viewModel.pauseQuotesUpdates()
        }

        if let requestedCategoryId {
            viewModel.select(categoryId: requestedCategoryId)
            self.requestedCategoryId = nil
        }

        shelfViewModel = viewModel
    }

    func select(categoryId: String?) {
        guard let shelfViewModel else {
            requestedCategoryId = categoryId
            return
        }

        shelfViewModel.select(categoryId: categoryId)
    }

    func feedSheetSizeDidChange(to size: ShtorkaSize) {
        sheetSize = size

        if size == .collapsed {
            shelfViewModel?.pauseQuotesUpdates()
        } else {
            shelfViewModel?.resumeQuotesUpdates()
        }
    }
}

// MARK: - RealAssetsWidgetRoutable

extension RealAssetsFeedViewModel: RealAssetsWidgetRoutable {
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel) {
        router.openToken(tokenInfo)
    }

    func openRealAssetsCategoryFilter(with input: RealAssetsCategoryFilterInput) {
        router.openCategoryFilter(with: input)
    }
}
