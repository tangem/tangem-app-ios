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

    var depositWalletAddress: String? { get }

    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }

    func refreshState() async
}

// MARK: - Default implementations

extension PolymarketAccountModel {
    var name: String {
        Localization.predictionAccountTitle
    }

    var icon: AccountModel.StandaloneIcon {
        .polymarket
    }

    var didChangePublisher: AnyPublisher<Void, Never> {
        .empty
    }

    func edit(with editor: (any AccountModelEditor) -> Void) async throws(AccountEditError) -> Self {
        self
    }

    func analyticsParameters(with builder: any AccountsAnalyticsBuilder) -> [Analytics.ParameterKey: String] {
        [:]
    }

    func resolve<R>(using resolver: R) -> R.Result where R: AccountModelResolving {
        resolver.resolve(accountModel: self)
    }
}
