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
    let yieldFeeContext: GaslessYieldFeeContext?

    private let balanceConverter = BalanceConverter()
}

struct GaslessYieldFeeContext {
    let yieldContractAddress: String
    let yieldModuleBalance: Decimal
    let feeTokenBalanceProvider: TokenBalanceProvider
    let versionChecker: YieldModuleVersionChecker?
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

        let result = try await resolveYieldFeeIfNeeded(
            fee: fee,
            spentAmount: sameFeeTokenSpendAmount(amount: amount.value, feeToken: params.feeToken),
            params: params,
            buildYieldFee: { yieldFeeOptions in
                try await gaslessTransactionFeeProvider.getEstimatedGaslessYieldFee(
                    feeToken: params.feeToken,
                    amount: amount,
                    feeRecipientAddress: params.feeRecipientAddress,
                    nativeToFeeTokenRate: params.nativeToFeeTokenRate,
                    yieldFeeOptions: yieldFeeOptions
                )
            }
        )

        return [result]
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

            let result = try await resolveYieldFeeIfNeeded(
                fee: fee,
                spentAmount: sameFeeTokenSpendAmount(amount: amount.value, feeToken: params.feeToken),
                params: params,
                buildYieldFee: { yieldFeeOptions in
                    try await gaslessTransactionFeeProvider.getGaslessYieldFee(
                        feeToken: params.feeToken,
                        amount: amount,
                        destination: destination,
                        feeRecipientAddress: params.feeRecipientAddress,
                        nativeToFeeTokenRate: params.nativeToFeeTokenRate,
                        yieldFeeOptions: yieldFeeOptions
                    )
                }
            )

            return [result]
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

        return try await resolveYieldFeeIfNeeded(
            fee: fee,
            spentAmount: 0,
            params: params,
            buildYieldFee: { yieldFeeOptions in
                try await gaslessTransactionFeeProvider.getEstimatedGaslessYieldTransactionFee(
                    feeToken: params.feeToken,
                    estimatedGasLimit: estimatedGasLimit,
                    otherNativeFee: otherNativeFee,
                    feeRecipientAddress: params.feeRecipientAddress,
                    nativeToFeeTokenRate: params.nativeToFeeTokenRate,
                    yieldFeeOptions: yieldFeeOptions
                )
            }
        )
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

        let result = try await resolveYieldFeeIfNeeded(
            fee: fee,
            spentAmount: sameFeeTokenSpendAmount(amount: request.amount, feeToken: params.feeToken),
            params: params,
            buildYieldFee: { yieldFeeOptions in
                try await gaslessTransactionFeeProvider.getGaslessYieldTransactionFee(
                    feeToken: params.feeToken,
                    destination: request.destination,
                    value: request.amount.encodedForSend,
                    data: request.txData,
                    otherNativeFee: request.otherNativeFee,
                    feeRecipientAddress: params.feeRecipientAddress,
                    nativeToFeeTokenRate: params.nativeToFeeTokenRate,
                    yieldFeeOptions: yieldFeeOptions
                )
            }
        )

        return [result]
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

    func resolveYieldFeeIfNeeded(
        fee: BSDKFee,
        spentAmount: Decimal,
        params: (feeToken: Token, feeRecipientAddress: String, nativeToFeeTokenRate: Decimal),
        buildYieldFee: (GaslessYieldFeeOptions) async throws -> BSDKFee
    ) async throws -> BSDKFee {
        guard let yieldFeeContext else {
            return fee
        }

        if cleanBalance(in: yieldFeeContext) >= requiredBalance(fee: fee, spentAmount: spentAmount) {
            return fee
        }

        let yieldFeeOptions = try await makeYieldFeeOptions(context: yieldFeeContext)
        let yieldFee = try await buildYieldFee(yieldFeeOptions)

        guard totalBalance(in: yieldFeeContext) >= requiredBalance(fee: yieldFee, spentAmount: spentAmount) else {
            throw TokenFeeLoaderError.notEnoughFeeBalance
        }

        return yieldFee
    }

    func makeYieldFeeOptions(context: GaslessYieldFeeContext) async throws -> GaslessYieldFeeOptions {
        guard let versionChecker = context.versionChecker else {
            return GaslessYieldFeeOptions(
                yieldContractAddress: context.yieldContractAddress,
                requiresUpgrade: false,
                upgradeImplementation: nil
            )
        }

        let status = try await versionChecker.checkVersion(userModuleAddress: context.yieldContractAddress)

        switch status {
        case .upToDate:
            return GaslessYieldFeeOptions(
                yieldContractAddress: context.yieldContractAddress,
                requiresUpgrade: false,
                upgradeImplementation: nil
            )
        case .outdated(canUpgrade: false, _):
            throw TokenFeeLoaderError.notEnoughFeeBalance
        case .outdated(canUpgrade: true, let latestImplementation):
            guard let latestImplementation else {
                throw TokenFeeLoaderError.notEnoughFeeBalance
            }

            return GaslessYieldFeeOptions(
                yieldContractAddress: context.yieldContractAddress,
                requiresUpgrade: true,
                upgradeImplementation: latestImplementation
            )
        }
    }

    func requiredBalance(fee: BSDKFee, spentAmount: Decimal) -> Decimal {
        fee.amount.value + spentAmount
    }

    func totalBalance(in context: GaslessYieldFeeContext) -> Decimal {
        context.feeTokenBalanceProvider.balanceType.value ?? 0
    }

    func cleanBalance(in context: GaslessYieldFeeContext) -> Decimal {
        max(totalBalance(in: context) - context.yieldModuleBalance, 0)
    }

    func sameFeeTokenSpendAmount(amount: Decimal, feeToken: Token) -> Decimal {
        tokenItem.contractAddress?.caseInsensitiveEquals(to: feeToken.contractAddress) == true ? amount : 0
    }

    func sameFeeTokenSpendAmount(amount: BSDKAmount, feeToken: Token) -> Decimal {
        amount.type.token?.contractAddress.caseInsensitiveEquals(to: feeToken.contractAddress) == true ? amount.value : 0
    }
}
