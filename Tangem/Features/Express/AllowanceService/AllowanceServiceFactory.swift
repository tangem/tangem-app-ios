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
        let tokenItem = walletModel.tokenItem
        let allowanceIsSupported = tokenItem.blockchain.isEvm && tokenItem.isToken

        guard allowanceIsSupported,
              let ethereumNetworkProvider = walletModel.ethereumNetworkProvider,
              let ethereumTransactionDataBuilder = walletModel.ethereumTransactionDataBuilder,
              walletModel.ethereumGaslessTransactionFeeProvider != nil
        else {
            return nil
        }

        let allowanceChecker = AllowanceChecker(
            blockchain: tokenItem.blockchain,
            amountType: tokenItem.amountType,
            walletAddress: walletModel.defaultAddress,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
        )

        return CommonAllowanceService(allowanceChecker: allowanceChecker)
    }
}
