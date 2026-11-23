//
//  CardanoResponseMapper.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CardanoResponseMapper {
    func mapToCardanoAddressResponse(
        tokens: [Token],
        unspentOutputs: [CardanoUnspentOutput],
        recentTransactionsHashes: [String]
    ) throws -> CardanoAddressResponse {
        let (coinBalance, isOverflow) = unspentOutputs.sumReportingOverflow(by: \.amount)

        guard !isOverflow else {
            throw BlockchainSdkError.failedToParseNetworkResponse()
        }

        let tokenBalances: [Token: Result<UInt64, Error>] = tokens.reduce(into: [:]) { tokenBalances, token in
            let assetFilter = CardanoAssetFilter(contractAddress: token.contractAddress)
            // Collecting of all output balance
            let (tokenBalance, isOverflow) = unspentOutputs
                // Sum with each asset in output amount
                .flatMap(\.assets)
                .filter { asset in
                    assetFilter.isEqualToAssetWith(policyId: asset.policyID, assetNameHex: asset.assetNameHex)
                }
                .sumReportingOverflow(by: \.amount)

            tokenBalances[token] = Result {
                guard !isOverflow else {
                    throw CardanoError.tokenBalanceOverflow
                }

                return tokenBalance
            }
        }

        return CardanoAddressResponse(
            balance: coinBalance,
            tokenBalances: tokenBalances,
            recentTransactionsHashes: recentTransactionsHashes,
            unspentOutputs: unspentOutputs
        )
    }
}
