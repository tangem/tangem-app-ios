//
//  MarketsItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class MarketsItemViewModel: Identifiable, ObservableObject {
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    // MARK: - Published

    @Published private(set) var tokenItemViewModel: MarketTokenItemViewModel

    // MARK: - Properties

    let index: Int
    let tokenId: String

    // MARK: - Private Properties

    private weak var prefetchDataSource: MarketsListPrefetchDataSource?

    // MARK: - Init

    init(
        index: Int,
        tokenModel: MarketsTokenModel,
        marketCapFormatter: MarketCapFormatter,
        prefetchDataSource: MarketsListPrefetchDataSource?,
        chartsProvider: MarketsListChartsHistoryProvider,
        filterProvider: MarketsListDataFilterProvider,
        onTapAction: (() -> Void)?
    ) {
        self.index = index
        tokenId = tokenModel.id
        self.prefetchDataSource = prefetchDataSource

        tokenItemViewModel = MarketTokenItemViewModel(
            tokenModel: tokenModel,
            marketCapFormatter: marketCapFormatter,
            chartsProvider: chartsProvider,
            filterProvider: filterProvider,
            onTapAction: onTapAction
        )
    }

    func onAppear() {
        prefetchDataSource?.prefetchRows(at: index)
    }

    func onDisappear() {
        prefetchDataSource?.cancelPrefetchingForRows(at: index)
    }
}
