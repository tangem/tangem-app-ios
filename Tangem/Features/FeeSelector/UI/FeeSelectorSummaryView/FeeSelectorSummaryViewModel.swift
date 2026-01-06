//
//  FeeSelectorSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeeSelectorSummaryRoutable: AnyObject {
    func userDidRequestTokenSelector()
    func userDidRequestFeeSelector()

    func userDidTapConfirmButton()
}

final class FeeSelectorSummaryViewModel: ObservableObject {
    // Some views

    private let tokensDataProvider: FeeSelectorTokensDataProvider
    private let feesDataProvider: FeeSelectorFeesDataProvider

    private weak var router: FeeSelectorSummaryRoutable?

    init(tokensDataProvider: FeeSelectorTokensDataProvider, feesDataProvider: FeeSelectorFeesDataProvider) {
        self.tokensDataProvider = tokensDataProvider
        self.feesDataProvider = feesDataProvider
    }

    func setup(router: FeeSelectorSummaryRoutable?) {
        self.router = router
    }

    func userDidTapToken() {
        router?.userDidRequestTokenSelector()
    }

    func userDidTapFee() {
        router?.userDidRequestFeeSelector()
    }
}
