//
//  PolymarketDepositNetworkResolver.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemAssets
import TangemFoundation
import TangemPolymarket

struct PolymarketDepositNetwork {
    let networkId: String
    let title: String
    let subtitle: String
    let icon: ImageType
    let receiveInput: PolymarketReceiveSheetViewModel.Input
}

enum PolymarketDepositNetworkResolver {
    static func resolve(
        depositTargets: [PolymarketAccountFundsInteractor.DepositTarget]
    ) -> [PolymarketDepositNetwork] {
        groupedByNetwork(depositTargets).compactMap(makeNetwork(from:))
    }
}

// MARK: - Private implementation

private extension PolymarketDepositNetworkResolver {
    typealias DepositTarget = PolymarketAccountFundsInteractor.DepositTarget

    static func groupedByNetwork(_ depositTargets: [DepositTarget]) -> [[DepositTarget]] {
        let grouped = depositTargets.grouped(by: \.entry.networkId)

        return depositTargets.uniqueProperties(\.entry.networkId).compactMap { grouped[$0] }
    }

    static func makeNetwork(from depositTargets: [DepositTarget]) -> PolymarketDepositNetwork? {
        guard let first = depositTargets.first else {
            return nil
        }

        let blockchain = first.tokenItem.blockchain

        guard let receiveInput = PolymarketReceiveSheetViewModel.Input(
            depositAddress: first.fundingAddress,
            minimumDepositFormatted: strictestMinimumFormatted(for: depositTargets),
            tokens: depositTargets.map(\.tokenItem)
        ) else {
            PolymarketLogger.warning("A deposit network is dropped: \(first.entry.networkId) targets do not share one network")
            return nil
        }

        return PolymarketDepositNetwork(
            networkId: first.entry.networkId,
            title: blockchain.displayName,
            subtitle: depositTargets.map(\.entry.symbol).joined(separator: ", "),
            icon: NetworkImageProvider().provide(by: blockchain, filled: true),
            receiveInput: receiveInput
        )
    }

    static func strictestMinimumFormatted(for depositTargets: [DepositTarget]) -> String {
        let minimum = depositTargets.map(\.minCheckoutUSD).max()

        return BalanceFormatter().formatFiatBalance(minimum, currencyCode: AppConstants.usdCurrencyCode)
    }
}
