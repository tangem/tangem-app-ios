//
//  PolymarketAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemLocalization

protocol PolymarketAccountModel: BaseAccountModel where Icon == AccountModel.StandaloneIcon, ID == PolymarketAccountId {
    var state: PolymarketAccountState? { get }
    var statePublisher: AnyPublisher<PolymarketAccountState?, Never> { get }

    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
    var collateralTokenBalanceProvider: TokenBalanceProvider { get }

    func refreshState(scope: PolymarketBalanceRefreshScope) async

    /// Reads the money only. The account's own status is terminal once it is ready to trade, so the
    /// screens behind it never ask for it again.
    func refreshBalance(scope: PolymarketBalanceRefreshScope) async
}

enum PolymarketBalanceRefreshScope {
    case full
    case availableOnly
}

// MARK: - Default implementations

extension PolymarketAccountModel {
    func refreshState() async {
        await refreshState(scope: .availableOnly)
    }

    var name: String {
        Localization.predictionAccountTitle
    }

    var icon: AccountModel.StandaloneIcon {
        .polymarket
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        .empty
    }

    func analyticsParameters(with builder: any AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        [:]
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
