//
//  AllowanceServiceFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct AllowanceServiceFactory {
    let walletModel: any WalletModel

    func makeAllowanceService() -> (any AllowanceService)? {
        makeAllowanceChecker().map { CommonAllowanceService(allowanceChecker: $0) }
    }
}

// MARK: - Private

private extension AllowanceServiceFactory {
    func makeAllowanceChecker() -> (any AllowanceChecking)? {
        let tokenItem = walletModel.tokenItem

        guard tokenItem.isToken else {
            return nil
        }

        if case .tron = tokenItem.blockchain {
            return makeTronAllowanceChecker(tokenItem: tokenItem)
        }

        if tokenItem.blockchain.isEvm {
            return makeEVMAllowanceChecker(tokenItem: tokenItem)
        }

        return nil
    }

    func makeTronAllowanceChecker(tokenItem: TokenItem) -> TronAllowanceChecker? {
        guard FeatureProvider.isAvailable(.tronDexSwap),
              let tronAllowanceProvider = walletModel.tronAllowanceProvider,
              let tronTransactionDataBuilder = walletModel.tronTransactionDataBuilder
        else {
            return nil
        }

        return TronAllowanceChecker(
            blockchain: tokenItem.blockchain,
            amountType: tokenItem.amountType,
            walletAddress: walletModel.defaultAddressString,
            allowanceProvider: tronAllowanceProvider,
            transactionDataBuilder: tronTransactionDataBuilder
        )
    }

    func makeEVMAllowanceChecker(tokenItem: TokenItem) -> EVMAllowanceChecker? {
        guard let ethereumNetworkProvider = walletModel.ethereumNetworkProvider,
              let ethereumTransactionDataBuilder = walletModel.ethereumTransactionDataBuilder,
              walletModel.ethereumGaslessTransactionFeeProvider != nil
        else {
            return nil
        }

        return EVMAllowanceChecker(
            blockchain: tokenItem.blockchain,
            amountType: tokenItem.amountType,
            walletAddress: walletModel.defaultAddressString,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
        )
    }
}
