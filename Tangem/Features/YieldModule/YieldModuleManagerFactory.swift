//
//  YieldModuleManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol YieldModuleWalletManagerFactory {
    func make(
        walletModel: any WalletModel
    ) -> YieldModuleWalletManager?
}

struct CommonYieldModuleWalletManagerFactory: YieldModuleWalletManagerFactory {
    private let signer: TangemSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let yieldSupplyService: YieldSupplyService
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder

    init(
        signer: TangemSigner,
        ethereumNetworkProvider: EthereumNetworkProvider,
        yieldSupplyService: YieldSupplyService,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder
    ) {
        self.signer = signer
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.yieldSupplyService = yieldSupplyService
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
    }

    func make(
        walletModel: any WalletModel
    ) -> YieldModuleWalletManager? {
        let dispatcher = YieldModuleTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer
        )

        return CommonYieldModuleWalletManager(
            walletModel: walletModel,
            yieldSupplyService: yieldSupplyService,
            tokenBalanceProvider: walletModel.totalTokenBalanceProvider,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder,
            transactionCreator: walletModel.transactionCreator,
            transactionDispatcher: dispatcher
        )
    }
}
