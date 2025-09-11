//
//  YieldModuleManagerFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol YieldModuleManagerFactory {
    func make(
        walletModel: any WalletModel
    ) -> YieldModuleManager
}

struct CommonYieldModuleManagerFactory: YieldModuleManagerFactory {
    private let token: Token
    private let blockchain: Blockchain
    private let signer: TangemSigner
    private let ethereumNetworkProvider: EthereumNetworkProvider
    private let yieldTokenService: YieldTokenService
    private let ethereumTransactionDataBuilder: EthereumTransactionDataBuilder
    
    init(
        token: Token,
        blockchain: Blockchain,
        signer: TangemSigner,
        ethereumNetworkProvider: EthereumNetworkProvider,
        yieldTokenService: YieldTokenService,
        ethereumTransactionDataBuilder: EthereumTransactionDataBuilder
    ) {
        self.token = token
        self.blockchain = blockchain
        self.signer = signer
        self.ethereumNetworkProvider = ethereumNetworkProvider
        self.yieldTokenService = yieldTokenService
        self.ethereumTransactionDataBuilder = ethereumTransactionDataBuilder
    }
    
    func make(
        walletModel: any WalletModel
    ) -> YieldModuleManager {
        let dispatcher = YieldModuleTransactionDispatcher(
            walletModel: walletModel,
            transactionSigner: signer
        )

        return CommonYieldModuleManager(
            walletAddress: walletModel.defaultAddressString,
            token: token,
            blockchain: blockchain,
            yieldTokenService: yieldTokenService,
            tokenBalanceProvider: walletModel.totalTokenBalanceProvider,
            ethereumNetworkProvider: ethereumNetworkProvider,
            ethereumTransactionDataBuilder: ethereumTransactionDataBuilder,
            transactionCreator: walletModel.transactionCreator,
            transactionDispatcher: dispatcher
        )
    }
}
