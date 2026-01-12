//
//  CommonExpressTokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine
import TangemFoundation

class CommonExpressTokenFeeManager {
    private let tokenItem: TokenItem
    private let tokenFeeManagerBuilder: TokenFeeManagerBuilder

    private let managers: ThreadSafeContainer<[ExpressProvider.Id: TokenFeeManager]> = [:]

    init(tokenItem: TokenItem, tokenFeeManagerBuilder: TokenFeeManagerBuilder) {
        self.tokenItem = tokenItem
        self.tokenFeeManagerBuilder = tokenFeeManagerBuilder
    }

    private func feeManager(_ provider: ExpressProvider) -> TokenFeeManager {
        if let feeManager = managers[provider.id] {
            return feeManager
        }

        let feeManager = tokenFeeManagerBuilder.makeTokenFeeManager()
        managers.mutate { $0[provider.id] = feeManager }

        return feeManager
    }

    private func mapToExpressFee(request: FeeRequest, tokenFeeProvider: TokenFeeProvider) throws -> BSDKFee {
        switch tokenFeeProvider.state {
        case .idle, .unavailable, .loading:
            throw ExpressSourceTokenFeeManagerError.feeNotFound
        case .error(let error):
            throw error
        case .available(let fees) where fees.count == 1:
            return fees[0]
        case .available(let fees) where fees.count == 3 && tokenItem.blockchain.isUTXO:
            return fees[1]
        case .available(let fees) where fees.count == 3:
            switch request.option {
            case .market: return fees[1]
            case .fast: return fees[2]
            }
        case .available:
            throw ExpressSourceTokenFeeManagerError.feeNotFound
        }
    }
}

// MARK: - ExpressTokenFeeManager

extension CommonExpressTokenFeeManager: ExpressTokenFeeManager {
    func tokenFeeManager(providerId: ExpressProvider.Id) -> TokenFeeManager? {
        guard let manager = managers[providerId] else {
            return nil
        }

        return manager
    }

    func selectedFeeProvider(providerId: ExpressProvider.Id) -> (any TokenFeeProvider)? {
        tokenFeeManager(providerId: providerId)?.selectedFeeProvider
    }

    func fees(providerId: ExpressProvider.Id) -> TokenFeesList {
        tokenFeeManager(providerId: providerId)?.fees ?? []
    }

    func feeTokenItems(providerId: ExpressProvider.Id) -> [TokenItem] {
        tokenFeeManager(providerId: providerId)?.selectedFeeProviderFeeTokenItems ?? []
    }

    func updateSelectedFeeTokenItem(tokenItem: TokenItem) {
        managers.values.forEach { tokenFeeManager in
            tokenFeeManager.updateSelectedFeeProvider(tokenItem: tokenItem)
        }
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressTokenFeeManager: ExpressFeeProvider {
    func estimatedFee(request: FeeRequest, amount: Decimal) async throws -> BSDKFee {
        let cexTokenFeeProvider = try feeManager(request.provider).selectedFeeProvider.asCEXTokenFeeProvider()
        await cexTokenFeeProvider.updateFees(amount: amount)

        return try mapToExpressFee(request: request, tokenFeeProvider: cexTokenFeeProvider)
    }

    func estimatedFee(request: FeeRequest, estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        let ethereumDEXTokenFeeProvider = try feeManager(request.provider).selectedFeeProvider.asEthereumDEXTokenFeeProvider()
        await ethereumDEXTokenFeeProvider.updateFees(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee)

        let expressFee = try mapToExpressFee(request: request, tokenFeeProvider: ethereumDEXTokenFeeProvider)
        return expressFee
    }

    func transactionFee(request: FeeRequest, data: ExpressTransactionDataType) async throws -> BSDKFee {
        switch (data, tokenItem.blockchain) {
        case (.cex(let data), _):
            let cexTokenFeeProvider = try feeManager(request.provider).selectedFeeProvider.asSimpleTokenFeeProvider()
            await cexTokenFeeProvider.updateFees(
                amount: data.fromAmount,
                destination: data.destinationAddress
            )

            return try mapToExpressFee(request: request, tokenFeeProvider: cexTokenFeeProvider)

        case (.dex(let data), .solana):
            guard let txData = data.txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            let solanaDEXTokenFeeProvider = try feeManager(request.provider).selectedFeeProvider.asSolanaDEXTokenFeeProvider()
            await solanaDEXTokenFeeProvider.updateFees(
                compiledTransaction: transactionData
            )

            return try mapToExpressFee(request: request, tokenFeeProvider: solanaDEXTokenFeeProvider)

        case (.dex(let data), _):
            guard let txData = data.txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // The `txValue` is always is coin
            let amount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: data.txValue)

            let ethereumDEXTokenFeeProvider = try feeManager(request.provider).selectedFeeProvider.asEthereumDEXTokenFeeProvider()
            await ethereumDEXTokenFeeProvider.updateFees(
                amount: amount,
                destination: data.destinationAddress,
                txData: txData,
                otherNativeFee: data.otherNativeFee
            )

            return try mapToExpressFee(request: request, tokenFeeProvider: ethereumDEXTokenFeeProvider)
        }
    }
}

enum ExpressSourceTokenFeeManagerError: LocalizedError {
    case feeNotFound

    var errorDescription: String? {
        switch self {
        case .feeNotFound: "Fee not found"
        }
    }
}
