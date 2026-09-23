//
//  TransactionHistoryAuxDataRepositoryStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation
import TangemStaking
@testable import Tangem

/// Resolves only the crypto currencies registered up front and records every one it was asked for.
final class TransactionHistoryAuxDataRepositoryStub: TransactionHistoryAuxDataRepository {
    private struct State {
        var tokens: [ExpressCurrency: TokenItem] = [:]
        var requestedCurrencies: [ExpressCurrency] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    var requestedCurrencies: [ExpressCurrency] {
        state.withLock { $0.requestedCurrencies }
    }

    func register(_ tokenItem: TokenItem, for currency: ExpressCurrency) {
        state.withLock { $0.tokens[currency] = tokenItem }
    }

    var didLoadAuxData: AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }

    func provider(id: ExpressProvider.Id, branch: ExpressBranch) -> ExpressProvider? { nil }

    func provider(id: ExpressProvider.Id, branch: ExpressBranch) async -> ExpressProvider? { nil }

    func fiatCurrency(for asset: OnrampHistoryFiatAsset) -> OnrampFiatCurrency? { nil }

    func fiatCurrency(for asset: OnrampHistoryFiatAsset) async -> OnrampFiatCurrency? { nil }

    func cryptoCurrency(for currency: ExpressCurrency, supportedBlockchains: Set<Blockchain>) -> TokenItem? {
        lookUp(currency)
    }

    func cryptoCurrency(for currency: ExpressCurrency, supportedBlockchains: Set<Blockchain>) async -> TokenItem? {
        lookUp(currency)
    }

    func stakingTarget(forAddress address: String, network: StakingNetworkType) -> StakingTargetSummary? { nil }

    private func lookUp(_ currency: ExpressCurrency) -> TokenItem? {
        state.withLock { state in
            state.requestedCurrencies.append(currency)
            return state.tokens[currency]
        }
    }
}
