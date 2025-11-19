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
    let transactionDispatcher: any TransactionDispatcher

    func makeAllowanceService() -> (any AllowanceService)? {
        let tokenItem = walletModel.tokenItem
        let allowanceIsSupported = tokenItem.blockchain.isEvm && tokenItem.isToken

        guard allowanceIsSupported else {
            return nil
        }

        let allowanceChecker = AllowanceChecker(
            blockchain: tokenItem.blockchain,
            amountType: tokenItem.amountType,
            walletAddress: walletModel.defaultAddressString,
            ethereumNetworkProvider: walletModel.ethereumNetworkProvider,
            ethereumTransactionDataBuilder: walletModel.ethereumTransactionDataBuilder
        )

        let approveTransactionProcessor = ExpressTransactionProcessorFactory(
            walletModel: walletModel,
            transactionDispatcher: transactionDispatcher,
        ).makeExpressApproveTransactionProcessor()

        return CommonAllowanceService(
            allowanceChecker: allowanceChecker,
            approveTransactionProcessor: approveTransactionProcessor
        )
    }
}
