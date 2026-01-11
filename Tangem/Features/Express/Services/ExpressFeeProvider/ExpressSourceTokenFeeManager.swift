//
//  ExpressSourceTokenFeeManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import Combine

class ExpressSourceTokenFeeManager {
    private let tokenItem: TokenItem
    private let tokenFeeManagerBuilder: TokenFeeManagerBuilder

    private var managers: [ExpressProvider.Id: TokenFeeManager] = [:]

    init(tokenItem: TokenItem, tokenFeeManagerBuilder: TokenFeeManagerBuilder) {
        self.tokenItem = tokenItem
        self.tokenFeeManagerBuilder = tokenFeeManagerBuilder
    }

    func feeManager(_ provider: ExpressProvider) -> TokenFeeManager {
        if let feeManager = managers[provider.id] {
            return feeManager
        }

        let feeManager = tokenFeeManagerBuilder.makeTokenFeeManager()
        managers[provider.id] = feeManager

        return feeManager
    }

    private func mapToExpressFee(tokenFeeProvider: TokenFeeProvider) throws -> ExpressFee.Variants {
        switch tokenFeeProvider.state {
        case .idle, .unavailable, .loading:
            throw ExpressFeeLoaderError.feeNotFound
        case .error(let error):
            throw error
        case .available(let fees) where fees.count == 1:
            return .single(fees[0])
        case .available(let fees) where fees.count == 3 && tokenItem.blockchain.isUTXO:
            return .single(fees[1])
        case .available(let fees) where fees.count == 3:
            return .double(market: fees[1], fast: fees[2])
        case .available:
            throw ExpressFeeLoaderError.feeNotFound
        }
    }
}

// MARK: - ExpressInteractorTokenFeeProvider

extension ExpressSourceTokenFeeManager: ExpressInteractorTokenFeeProvider {
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
}

// MARK: - ExpressFeeProvider

extension ExpressSourceTokenFeeManager: ExpressFeeProvider {
    func estimatedFee(provider: ExpressProvider, amount: Decimal) async throws -> ExpressFee.Variants {
        let cexTokenFeeProvider = try feeManager(provider).selectedFeeProvider.asCEXTokenFeeProvider()
        await cexTokenFeeProvider.updateFees(amount: amount)

        return try mapToExpressFee(tokenFeeProvider: cexTokenFeeProvider)
    }

    func estimatedFee(provider: ExpressProvider, estimatedGasLimit: Int) async throws -> Fee {
        let ethereumDEXTokenFeeProvider = try feeManager(provider).selectedFeeProvider.asEthereumDEXTokenFeeProvider()
        await ethereumDEXTokenFeeProvider.updateFees(estimatedGasLimit: estimatedGasLimit)

        let expressFee = try mapToExpressFee(tokenFeeProvider: ethereumDEXTokenFeeProvider)
        return expressFee.fastest
    }

    func getFee(provider: ExpressProvider, amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants {
        switch (amount, tokenItem.blockchain) {
        case (.transfer(let amount), _):
            return try await estimatedFee(provider: provider, amount: amount)

        case (.dex(_, _, let txData), .solana):
            guard let txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            let solanaDEXTokenFeeProvider = try feeManager(provider).selectedFeeProvider.asSolanaDEXTokenFeeProvider()
            await solanaDEXTokenFeeProvider.updateFees(compiledTransaction: transactionData)

            return try mapToExpressFee(tokenFeeProvider: solanaDEXTokenFeeProvider)

        case (.dex(_, let txValue, let txData), _):
            guard let txData = txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // The `txValue` is always is coin
            let amount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: txValue)

            let ethereumDEXTokenFeeProvider = try feeManager(provider).selectedFeeProvider.asEthereumDEXTokenFeeProvider()
            await ethereumDEXTokenFeeProvider.updateFees(amount: amount, destination: destination, txData: txData)

            return try mapToExpressFee(tokenFeeProvider: ethereumDEXTokenFeeProvider)
        }
    }
}

extension ExpressFee.Variants {
    var fastest: Fee {
        switch self {
        case .double(_, let fast): return fast
        case .single(let fee): return fee
        }
    }
}
