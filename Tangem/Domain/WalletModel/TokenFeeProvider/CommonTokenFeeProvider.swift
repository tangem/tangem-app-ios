//
//  CommonTokenFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct CommonTokenFeeProvider {
    let tokenItem: TokenItem
    let walletManager: any WalletManager
}

// MARK: - TokenFeeProvider

extension CommonTokenFeeProvider: TokenFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let amount = makeAmount(amount: amount)
        let fees = try await walletManager.estimatedFee(amount: amount).async()
        return fees
    }

    func getFee(dataType: TokenFeeProviderDataType) async throws -> [BSDKFee] {
        switch dataType {
        case .plain(let amount, let destination):
            let amount = makeAmount(amount: amount)
            let fees = try await walletManager.getFee(amount: amount, destination: destination).async()
            return fees

        case .compiledTransaction(let data):
            guard let walletManager = walletManager as? CompiledTransactionFeeProvider else {
                throw TokenFeeProviderError.tokenFeeProviderDataTypeNotSupported
            }

            let fees = try await walletManager.getFee(compiledTransaction: data)
            return fees
        }
    }
}

// MARK: - Private

private extension CommonTokenFeeProvider {
    func makeAmount(amount: Decimal) -> BSDKAmount {
        BSDKAmount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
    }
}
