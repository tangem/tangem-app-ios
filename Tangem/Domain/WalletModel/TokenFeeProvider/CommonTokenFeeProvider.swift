//
//  CommonTokenFeeLoader.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct CommonTokenFeeLoader {
    let feeTokenItem: TokenItem
    let walletManager: any WalletManager
}

// MARK: - TokenFeeLoader

extension CommonTokenFeeLoader: TokenFeeLoader {
    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        let amount = makeAmount(amount: amount)
        let fees = try await walletManager.estimatedFee(amount: amount).async()
        return fees
    }

    func getFee(dataType: TokenFeeLoaderDataType) async throws -> [BSDKFee] {
        switch dataType {
        case .plain(let amount, let destination):
            let amount = makeAmount(amount: amount)
            let fees = try await walletManager.getFee(amount: amount, destination: destination).async()
            return fees

        case .compiledTransaction(let data):
            guard let walletManager = walletManager as? CompiledTransactionFeeProvider else {
                throw TokenFeeLoaderError.tokenFeeProviderDataTypeNotSupported
            }

            let fees = try await walletManager.getFee(compiledTransaction: data)
            return fees

        case .gaslessTransaction(let feeToken, let amount, let destination):
            guard let walletManager = walletManager as? GaslessTransactionFeeProvider,
                  let token = feeToken.token
            else {
                throw TokenFeeProviderError.tokenFeeProviderDataTypeNotSupported
            }

            let bsdkAmount = makeAmount(amount: amount)
            let fee = try await walletManager.getGaslessFee(feeToken: token, originalAmount: bsdkAmount, originalDestination: destination)
            return [fee]
        }
    }
}

// MARK: - Private

private extension CommonTokenFeeLoader {
    func makeAmount(amount: Decimal) -> BSDKAmount {
        BSDKAmount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: amount)
    }
}
