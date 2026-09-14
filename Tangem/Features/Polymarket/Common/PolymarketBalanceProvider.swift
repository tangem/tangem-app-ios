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

    var collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never> { get }

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

    var collateralBalancePublisher: AnyPublisher<TokenBalanceType, Never> {
        guard let accountModel else {
            return .just(output: .empty(.noData))
        }

        return accountModel.collateralTokenBalanceProvider.balanceTypePublisher
    }

    func refresh() async {
        await accountModel?.refreshState()
    }
}
