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

    func getFee(request: EthereumFeeRequestData) async throws -> [BSDKFee] {
        let params = try await resolveGaslessParameters()

        let fee = try await gaslessTransactionFeeProvider.getGaslessTransactionFee(
            feeToken: params.feeToken,
            destination: request.destination,
            value: request.amount.encodedForSend,
            data: request.txData,
            stateOverride: nil,
            otherNativeFee: request.otherNativeFee,
            feeRecipientAddress: params.feeRecipientAddress,
            nativeToFeeTokenRate: params.nativeToFeeTokenRate
        )

        return [fee]
    }

    func getApproveWithSwapFee(request: EthereumFeeRequestData, approveInput: ApproveWithSwapInput) async throws -> [BSDKFee] {
        let params = try await resolveGaslessParameters()

        let unlimitedAllowanceOverride = EthereumAccountOverride.unlimitedAllowance(
            tokenAddress: approveInput.tokenContractAddress,
            owner: approveInput.owner,
            spender: approveInput.spender
        )

        async let swapFeeTask = gaslessTransactionFeeProvider.getGaslessTransactionFee(
            feeToken: params.feeToken,
            destination: request.destination,
            value: request.amount.encodedForSend,
            data: request.txData,
            stateOverride: unlimitedAllowanceOverride,
            otherNativeFee: request.otherNativeFee,
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
        return [try ApproveWithSwapFeeParameters.combinedFee(swapFee: swapFee, approveFee: approveFee)]
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
