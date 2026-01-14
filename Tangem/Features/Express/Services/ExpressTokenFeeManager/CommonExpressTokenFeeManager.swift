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
        tokenFeeManager(providerId: providerId)?.selectedFeeProviderFees ?? []
    }

    func feeTokenProviders(providerId: ExpressProvider.Id) -> [any TokenFeeProvider] {
        tokenFeeManager(providerId: providerId)?.feeTokenProviders ?? []
    }

    func updateSelectedFeeTokenProviderInAllManagers(tokenFeeProvider: any TokenFeeProvider) {
        managers.values.forEach { tokenFeeManager in
            tokenFeeManager.updateSelectedFeeProvider(tokenFeeProvider: tokenFeeProvider)
            tokenFeeManager.updateSelectedFeeProviderFees()
        }
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressTokenFeeManager: ExpressFeeProvider {
    func estimatedFee(request: FeeRequest, amount: Decimal) async throws -> BSDKFee {
        let feeManager = feeManager(request.provider)
        feeManager.setupFeeProviders(input: .cex(amount: amount))
        await feeManager.selectedFeeProvider.updateFees()

        let tokenFeeProvider = feeManager.selectedFeeProvider
        return try mapToExpressFee(request: request, tokenFeeProvider: tokenFeeProvider)
    }

    func estimatedFee(request: FeeRequest, estimatedGasLimit: Int, otherNativeFee: Decimal?) async throws -> BSDKFee {
        let feeManager = feeManager(request.provider)
        feeManager.setupFeeProviders(input: .dex(.ethereumEstimate(estimatedGasLimit: estimatedGasLimit, otherNativeFee: otherNativeFee)))
        await feeManager.selectedFeeProvider.updateFees()

        let tokenFeeProvider = feeManager.selectedFeeProvider
        return try mapToExpressFee(request: request, tokenFeeProvider: tokenFeeProvider)
    }

    func transactionFee(request: FeeRequest, data: ExpressTransactionDataType) async throws -> BSDKFee {
        let feeManager = feeManager(request.provider)
        let tokenFeeProvider = feeManager.selectedFeeProvider

        switch (data, tokenItem.blockchain) {
        case (.cex(let data), _):
            feeManager.setupFeeProviders(input: .common(amount: data.fromAmount, destination: data.destinationAddress))
            await feeManager.selectedFeeProvider.updateFees()

            return try mapToExpressFee(request: request, tokenFeeProvider: tokenFeeProvider)

        case (.dex(let data), .solana):
            guard let txData = data.txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            feeManager.setupFeeProviders(input: .dex(.solana(compiledTransaction: transactionData)))
            await feeManager.selectedFeeProvider.updateFees()

            return try mapToExpressFee(request: request, tokenFeeProvider: tokenFeeProvider)

        case (.dex(let data), _):
            guard let txData = data.txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // The `txValue` is always is coin
            let amount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: data.txValue)
            feeManager.setupFeeProviders(input: .dex(.ethereum(
                amount: amount,
                destination: data.destinationAddress,
                txData: txData,
                otherNativeFee: data.otherNativeFee
            )))
            await feeManager.selectedFeeProvider.updateFees()
            return try mapToExpressFee(request: request, tokenFeeProvider: tokenFeeProvider)
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
