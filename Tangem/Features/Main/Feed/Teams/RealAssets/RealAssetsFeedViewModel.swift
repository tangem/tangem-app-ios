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

    private weak var routable: (any FeedRoutable)?
    private var sheetSize: ShtorkaSize = .collapsed

    init(routable: any FeedRoutable) {
        self.routable = routable
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
            coordinator: self
        )

        if sheetSize == .collapsed {
            viewModel.pauseQuotesUpdates()
        }

        shelfViewModel = viewModel
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
        routable?.openToken(tokenInfo)
    }

    func openRealAssetsCategoryFilter(with input: RealAssetsCategoryFilterInput) {
        routable?.openRealAssetsCategoryFilter(with: input)
    }
}
