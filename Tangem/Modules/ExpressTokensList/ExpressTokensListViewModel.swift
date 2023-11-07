//
//  ExpressTokensListViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI

class ExpressTokensListRoutableMock: ExpressTokensListRoutable {
    init() {}
}

final class ExpressTokensListViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var searchText: String = ""
    @Published var availableTokens: [SwappingTokenItemViewModel] = []
    @Published var unavailableTokens: [SwappingTokenItemViewModel] = []

    // MARK: - Dependencies

    private unowned let coordinator: ExpressTokensListRoutable

    init(coordinator: ExpressTokensListRoutable) {
        self.coordinator = coordinator
        setupView()
    }
}

// MARK: - Private

private extension ExpressTokensListViewModel {
    func setupView() {
        availableTokens = [
            .init(
                tokenId: "BNB",
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                name: "Bitcoin",
                symbol: "BTC",
                balance: CurrencyAmount(value: 0.12414, currency: .mock),
                fiatBalance: 4352,
                itemDidTap: {}
            ),
            .init(
                tokenId: "BNB",
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                name: "Bitcoin",
                symbol: "BTC",
                balance: CurrencyAmount(value: 0.12414, currency: .mock),
                fiatBalance: 4352,
                itemDidTap: {}
            ),
            .init(
                tokenId: "BNB",
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                name: "Bitcoin",
                symbol: "BTC",
                balance: CurrencyAmount(value: 0.12414, currency: .mock),
                fiatBalance: 4352,
                itemDidTap: {}
            ),
        ]

        unavailableTokens = [
            .init(
                tokenId: "BNB",
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                name: "Bitcoin",
                symbol: "BTC",
                balance: CurrencyAmount(value: 0.12414, currency: .mock),
                fiatBalance: 4352,
                itemDidTap: {}
            ),
            .init(
                tokenId: "BNB",
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                name: "Bitcoin",
                symbol: "BTC",
                balance: CurrencyAmount(value: 0.12414, currency: .mock),
                fiatBalance: 4352,
                itemDidTap: {}
            ),
            .init(
                tokenId: "BNB",
                iconURL: TokenIconURLBuilder().iconURL(id: "bitcoin"),
                name: "Bitcoin",
                symbol: "BTC",
                balance: CurrencyAmount(value: 0.12414, currency: .mock),
                fiatBalance: 4352,
                itemDidTap: {}
            ),
        ]
    }
}
