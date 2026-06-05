//
//  CommonGaslessTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
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
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let params = try await resolveGaslessParameters()
        let amount = makeAmount(amount: amount)

        let fee = try await gaslessTransactionFeeProvider.getEstimatedGaslessFee(
            feeToken: params.feeToken,
            amount: amount,
            feeRecipientAddress: params.feeRecipientAddress,
            nativeToFeeTokenRate: params.nativeToFeeTokenRate
        )

        return [fee]
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        let params = try await resolveGaslessParameters()
        let amount = makeAmount(amount: amount)

        do {
            let fee = try await gaslessTransactionFeeProvider.getGaslessFee(
                feeToken: params.feeToken,
                amount: amount,
                destination: destination,
                feeRecipientAddress: params.feeRecipientAddress,
                nativeToFeeTokenRate: params.nativeToFeeTokenRate
            )

            return [fee]
        } catch let error where error.isEVMExecutionReverted {
            throw TokenFeeLoaderError.gaslessExecutionReverted(gaslessMinTokenAmount: EthereumFeeParametersConstants.gaslessMinTokenAmountDecimal)
        }
    }
}

// MARK: - EthereumTokenFeeLoader

extension CommonGaslessTokenFeeLoader: EthereumTokenFeeLoader {
    func estimatedFee(estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        let params = try await resolveGaslessParameters()

        let fee = try await gaslessTransactionFeeProvider.getEstimatedGaslessTransactionFee(
            feeToken: params.feeToken,
            estimatedGasLimit: estimatedGasLimit,
            otherNativeFee: otherNativeFee,
            feeRecipientAddress: params.feeRecipientAddress,
            nativeToFeeTokenRate: params.nativeToFeeTokenRate
        )

        return fee
    }

    func getFee(
        amount: BSDKAmount,
        destination: String,
        txData: Data,
        otherNativeFee: Decimal?,
        approveInput: ApproveWithSwapInput?
    ) async throws -> [BSDKFee] {
        let params = try await resolveGaslessParameters()

        guard let approveInput else {
            let fee = try await gaslessTransactionFeeProvider.getGaslessTransactionFee(
                feeToken: params.feeToken,
                destination: destination,
                value: amount.encodedForSend,
                data: txData,
                stateOverride: nil,
                otherNativeFee: otherNativeFee,
                feeRecipientAddress: params.feeRecipientAddress,
                nativeToFeeTokenRate: params.nativeToFeeTokenRate
            )

            return [fee]
        }

        // The swap gas estimate would revert while the allowance is missing, so it runs
        // with the allowance overridden to unlimited — covering the `transferFrom` gas.
        let unlimitedAllowanceOverride = EthereumAccountOverride.unlimitedAllowance(
            tokenAddress: approveInput.tokenContractAddress,
            owner: approveInput.owner,
            spender: approveInput.spender
        )

        // Both estimates run through the gasless provider, so the approve fee is always
        // denominated in the fee token.
        async let swapFeeTask = gaslessTransactionFeeProvider.getGaslessTransactionFee(
            feeToken: params.feeToken,
            destination: destination,
            value: amount.encodedForSend,
            data: txData,
            stateOverride: unlimitedAllowanceOverride,
            otherNativeFee: otherNativeFee,
            feeRecipientAddress: params.feeRecipientAddress,
            nativeToFeeTokenRate: params.nativeToFeeTokenRate
        )
        async let approveFeeTask = gaslessTransactionFeeProvider.getGaslessTransactionFee(
            feeToken: params.feeToken,
            destination: approveInput.tokenContractAddress,
            value: BSDKAmount(with: tokenItem.blockchain, type: .coin, value: 0).encodedForSend,
            data: approveInput.txData,
            stateOverride: nil,
            otherNativeFee: nil,
            feeRecipientAddress: params.feeRecipientAddress,
            nativeToFeeTokenRate: params.nativeToFeeTokenRate
        )

        let (swapFee, approveFee) = try await (swapFeeTask, approveFeeTask)

        var combinedFeeAmount = swapFee.amount
        combinedFeeAmount.value += approveFee.amount.value

        guard let swapParameters = swapFee.parameters as? any EthereumFeeParameters else {
            return [BSDKFee(combinedFeeAmount, parameters: swapFee.parameters)]
        }

        return [BSDKFee(
            combinedFeeAmount,
            parameters: ApproveWithSwapFeeParameters(swapParameters: swapParameters, approveFee: approveFee)
        )]
    }
}

// MARK: - Private

private extension CommonGaslessTokenFeeLoader {
    func makeAmount(amount: Decimal) -> BSDKAmount {
        BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
    }

    func resolveGaslessParameters() async throws -> (feeToken: Token, feeRecipientAddress: String, nativeToFeeTokenRate: Decimal) {
        guard let feeToken else {
            throw TokenFeeLoaderError.gaslessEthereumTokenFeeSupportOnlyTokenAsFeeTokenItem
        }

        guard let feeRecipientAddress = await networkManager.feeRecipientAddress else {
            throw TokenFeeLoaderError.missingFeeRecipientAddress
        }

        guard let feeAssetId = feeToken.id else {
            throw TokenFeeLoaderError.feeTokenIdNotFound
        }

        let nativeAssetId = tokenItem.blockchain.coinId
        let nativeToFeeTokenRate = try await balanceConverter.cryptoToCryptoRate(from: nativeAssetId, to: feeAssetId)

        return (feeToken, feeRecipientAddress, nativeToFeeTokenRate)
    }
}
