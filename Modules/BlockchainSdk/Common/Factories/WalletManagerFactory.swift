//
//  WalletManagerFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemNetworkUtils

@available(iOS 13.0, *)
public class WalletManagerFactory {
    private let blockchainSdkKeysConfig: BlockchainSdkKeysConfig
    private let dependencies: BlockchainSdkDependencies
    private let tangemProviderConfiguration: TangemProviderConfiguration
    private let apiList: APIList

    // MARK: - Init

    public init(
        blockchainSdkKeysConfig: BlockchainSdkKeysConfig,
        tangemProviderConfiguration: TangemProviderConfiguration = TangemProviderConfiguration.ephemeralConfiguration,
        dependencies: BlockchainSdkDependencies,
        apiList: APIList
    ) {
        self.blockchainSdkKeysConfig = blockchainSdkKeysConfig
        self.tangemProviderConfiguration = tangemProviderConfiguration
        self.dependencies = dependencies
        self.apiList = apiList
    }

    /// For a wallet put together by `WalletFactory` or, when it lives somewhere no key derives, by the caller itself.
    public func makeWalletManager(wallet: Wallet) throws -> WalletManager {
        let blockchain = wallet.blockchain

        let networkInput = NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: blockchainSdkKeysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfiguration
        )

        let input = WalletManagerAssemblyInput(
            wallet: wallet,
            blockchainSdkDependencies: dependencies,
            networkInput: networkInput
        )

        return try blockchain.assembly.make(with: input)
    }
}
