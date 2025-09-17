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
    ) throws -> YieldModuleWalletManager
}

struct CommonYieldModuleWalletManagerFactory: YieldModuleWalletManagerFactory {
    private let token: Token
    private let blockchain: Blockchain
    private let signer: TangemSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let yieldSupplyProvider: YieldSupplyProvider
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder

    init(
        token: Token,
        blockchain: Blockchain,
        signer: TangemSigner,
        ethereumNetworkProvider: EthereumNetworkProvider,
        yieldSupplyProvider: YieldSupplyProvider,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder
    ) {
        self.token = token
        self.blockchain = blockchain
        self.signer = signer
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.yieldSupplyProvider = yieldSupplyProvider
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
    }

    func make(
        walletModel: any WalletModel
    ) throws -> YieldModuleWalletManager {
        let dispatcher = YieldModuleTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer
        )

        return try CommonYieldModuleWalletManager(
            walletModel: walletModel,
            token: token,
            blockchain: blockchain,
            yieldSupplyProvider: yieldSupplyProvider,
            tokenBalanceProvider: walletModel.totalTokenBalanceProvider,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder,
            transactionCreator: walletModel.transactionCreator,
            transactionDispatcher: dispatcher
        )
    }
}
