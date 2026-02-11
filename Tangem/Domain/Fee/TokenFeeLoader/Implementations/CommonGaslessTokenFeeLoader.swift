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
    @Injected(\.gaslessTransactionsNetworkManager) var networkManager: GaslessTransactionsNetworkManager

    let tokenItem: TokenItem
    let feeToken: Token?
    let gaslessTransactionFeeProvider: any GaslessTransactionFeeProvider

    private let balanceConverter = BalanceConverter()
}

// MARK: - TokenFeeLoader

extension CommonGaslessTokenFeeLoader: TokenFeeLoader {
    var allowsFeeSelection: Bool { false }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        guard let feeToken else {
            throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
        }

        guard let feeRecipientAddress = await networkManager.feeRecipientAddress else {
            throw TokenFeeLoaderError.missingFeeRecipientAddress
        }

        let amount = makeAmount(amount: amount)

        // Native coin of the network (e.g. ETH)
        let nativeAssetId = tokenItem.blockchain.coinId

        // Asset used to pay the fee
        guard let feeAssetId = feeToken.id else {
            throw TokenFeeLoaderError.feeTokenIdNotFound
        }

        // Calculate coin-to-token rate
        let nativeToFeeTokenRate = try await balanceConverter.cryptoToCryptoRate(from: nativeAssetId, to: feeAssetId)

        let fee = try await gaslessTransactionFeeProvider.getEstimatedGaslessFee(
            feeToken: feeToken,
            amount: amount,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate
        )

        return [fee]
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        guard let feeToken else {
            throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
        }

        guard let feeRecipientAddress = await networkManager.feeRecipientAddress else {
            throw TokenFeeLoaderError.missingFeeRecipientAddress
        }

        // Asset used to pay the fee (e.g. USDC)
        guard let feeAssetId = feeToken.id else {
            throw TokenFeeLoaderError.feeTokenIdNotFound
        }

        // Native coin of the network (e.g. ETH)
        let nativeAssetId = tokenItem.blockchain.coinId

        // Calculate coin-to-token rate
        let nativeToFeeTokenRate = try await balanceConverter.cryptoToCryptoRate(
            from: nativeAssetId,
            to: feeAssetId
        )

        let amount = makeAmount(amount: amount)

        let fee = try await gaslessTransactionFeeProvider.getGaslessFee(
            feeToken: feeToken,
            amount: amount,
            destination: destination,
            feeRecipientAddress: feeRecipientAddress,
            nativeToFeeTokenRate: nativeToFeeTokenRate
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
