//
//  FakeBalanceWithButtonsInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class FakeBalanceWithButtonsInfoProvider {
    @Published var models: [BalanceWithButtonsViewModel] = []
    @Published var modelsWithButtons: [BalanceWithButtonsViewModel] = []

    private let balanceProvidersWithoutButtons = [
        FakeTokenBalanceProvider(
            buttons: [],
            delay: 0,
            cryptoBalanceInfo: .init(balance: "1031232431232151004.435432 BTC", fiatBalance: "–")
        ),
    ]

    private let balanceProvidersWithButtons = [
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, disabled: true, action: {}),
                .init(title: "Send", icon: Assets.arrowUpMini, disabled: false, action: {}),
            ],
            delay: 5,
            cryptoBalanceInfo: .init(balance: "1034.435432 ETH", fiatBalance: "–")
        ),
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, disabled: false, action: {}),
                .init(title: "Send", icon: Assets.arrowUpMini, disabled: false, action: {}),
                .init(title: "Receive", icon: Assets.arrowDownMini, action: {}),
                .init(title: "Exchange", icon: Assets.exchangeMini, disabled: false, action: {}),
                .init(title: "Sell your soul", icon: Assets.cryptoCurrencies, disabled: false, action: {}),
                .init(title: "Dance", icon: Assets.swapHeart, disabled: false, action: {}),
            ],
            delay: 3,
            cryptoBalanceInfo: .init(balance: "-1 MATIC", fiatBalance: "–")
        ),
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, action: {}),
                .init(title: "Send", icon: Assets.arrowUpMini, action: {}),
            ],
            delay: 6,
            cryptoBalanceInfo: .init(balance: "4.4212312 XLM", fiatBalance: "2.24$")
        ),
    ]

    init() {
        models = (balanceProvidersWithoutButtons + balanceProvidersWithButtons).map(map(_:))
        modelsWithButtons = balanceProvidersWithButtons.map(map(_:))
    }

    func map(_ provider: FakeTokenBalanceProvider) -> BalanceWithButtonsViewModel {
        BalanceWithButtonsViewModel(
            balanceProvider: provider,
            availableBalanceProvider: nil,
            buttonsProvider: provider
        )
    }
}
