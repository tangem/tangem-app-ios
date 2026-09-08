//
//  PolymarketBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol PolymarketBalanceProvider {
    var balancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var collateralPublisher: AnyPublisher<Decimal?, Never> { get }

    func refresh() async
}

struct CommonPolymarketBalanceProvider: PolymarketBalanceProvider {
    private let accountModel: (any PolymarketAccountModel)?

    init(userWalletModel: (any UserWalletModel)?) {
        accountModel = userWalletModel
            .map(\.accountModelsManager)
            .flatMap(PolymarketAccountAggregator.polymarketAccountModel(from:))
    }

    var balancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        guard let accountModel else {
            return .just(output: .failure(.empty(BalanceFormatter.defaultEmptyBalanceString)))
        }

        return accountModel.fiatTotalTokenBalanceProvider.formattedBalanceTypePublisher
    }

    var collateralPublisher: AnyPublisher<Decimal?, Never> {
        guard let accountModel else {
            return .just(output: nil)
        }

        return accountModel.collateralTokenBalanceProvider.balanceTypePublisher
            .map(\.value)
            .eraseToAnyPublisher()
    }

    func refresh() async {
        await accountModel?.refreshState()
    }
}
