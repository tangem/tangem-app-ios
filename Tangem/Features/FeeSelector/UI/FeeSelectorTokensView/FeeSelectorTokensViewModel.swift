//
//  FeeSelectorTokensViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol FeeSelectorTokensDataProvider {
    var selectedFeeTokenItem: TokenItem? { get }
    var selectedFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> { get }

    var feeTokenItems: [TokenItem] { get }
    var feeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> { get }
}

protocol FeeSelectorTokensRoutable: AnyObject {
    func userDidSelectFeeToken()
}

final class FeeSelectorTokensViewModel: ObservableObject {
    // Some views

    private let tokensDataProvider: FeeSelectorTokensDataProvider

    private weak var router: FeeSelectorTokensRoutable?

    init(tokensDataProvider: FeeSelectorTokensDataProvider) {
        self.tokensDataProvider = tokensDataProvider
    }

    func setup(router: FeeSelectorTokensRoutable?) {
        self.router = router
    }

    func userDidSelectFeeToken() {
        router?.userDidSelectFeeToken()
    }
}
