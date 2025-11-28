//
//  FakeBalanceWithButtonsInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets

class FakeBalanceWithButtonsInfoProvider {
    @Published var models: [BalanceWithButtonsViewModel] = []
    @Published var modelsWithButtons: [BalanceWithButtonsViewModel] = []

    private let balanceProvidersWithoutButtons = [
        FakeTokenBalanceProvider(
            buttons: [],
            delay: 0,
            cryptoBalanceInfo: (crypto: "1031232431232151004.435432 BTC", fiat: AppConstants.enDashSign)
        ),
    ]

    private let balanceProvidersWithButtons = [
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, disabled: true, action: {}),
                .init(title: "Send", icon: Assets.arrowUpMini, disabled: false, action: {}),
            ],
            delay: 5,
            cryptoBalanceInfo: (crypto: "1034.435432 ETH", fiat: AppConstants.enDashSign)
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
            cryptoBalanceInfo: (crypto: "-1 MATIC", fiat: AppConstants.enDashSign)
        ),
        FakeTokenBalanceProvider(
            buttons: [
                .init(title: "Buy", icon: Assets.plusMini, action: {}),
                .init(title: "Send", icon: Assets.arrowUpMini, action: {}),
            ],
            delay: 6,
            cryptoBalanceInfo: (crypto: "4.4212312 XLM", fiat: "2.24$")
        ),
    ]

    init() {
        models = (balanceProvidersWithoutButtons + balanceProvidersWithButtons).map(map(_:))
        modelsWithButtons = balanceProvidersWithButtons.map(map(_:))
    }

    func map(_ provider: FakeTokenBalanceProvider) -> BalanceWithButtonsViewModel {
        BalanceWithButtonsViewModel(
            tokenItem: .blockchain(.init(.bitcoin(testnet: false), derivationPath: nil)),
            buttonsPublisher: provider.buttonsPublisher,
            balanceProvider: provider,
            balanceTypeSelectorProvider: provider,
            yieldModuleStatusProvider: provider,
            refreshStatusProvider: provider,
            showYieldBalanceInfoAction: {},
            reloadBalance: {}
        )
    }
}
