//
//  CommonGaslessTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk

struct CommonGaslessTokenFeeLoader {
    let tokenItem: TokenItem
    let feeToken: Token?
    let gaslessTransactionFeeProvider: any GaslessTransactionFeeProvider
}

// MARK: - TokenFeeLoader

extension CommonGaslessTokenFeeLoader: TokenFeeLoader {
    var allowsFeeSelection: Bool { false }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        guard let feeToken else {
            throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
        }

        let amount = makeAmount(amount: amount)
        let fee = try await gaslessTransactionFeeProvider.getEstimatedGaslessFee(
            feeToken: feeToken,
            amount: amount
        )

        return [fee]
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        guard let feeToken else {
            throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
        }

        let amount = makeAmount(amount: amount)
        let fee = try await gaslessTransactionFeeProvider.getGaslessFee(
            feeToken: feeToken,
            amount: amount,
            destination: destination
        )

        return [fee]
    }
}

// MARK: - Private

private extension CommonGaslessTokenFeeLoader {
    func makeAmount(amount: Decimal) -> BSDKAmount {
        BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
    }
}
