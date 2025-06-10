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

    public func makeWalletManager(blockchain: Blockchain, publicKey: Wallet.PublicKey) throws -> WalletManager {
        let walletFactory = WalletFactory(blockchain: blockchain)
        let wallet = try walletFactory.makeWallet(publicKey: publicKey)
        return try makeWalletManager(wallet: wallet)
    }

    /// Only for Tangem Twin Cards
    /// - Parameters:
    ///   - walletPublicKey: First public key
    ///   - pairKey: Pair public key
    public func makeTwinWalletManager(walletPublicKey: Data, pairKey: Data, isTestnet: Bool) throws -> WalletManager {
        let blockchain: Blockchain = .bitcoin(testnet: isTestnet)
        let publicKey = Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
        let walletFactory = WalletFactory(blockchain: blockchain)
        let wallet = try walletFactory.makeWallet(publicKey: publicKey, pairPublicKey: pairKey)
        return try makeWalletManager(wallet: wallet, pairPublicKey: pairKey)
    }
}

// MARK: - Private Implementation

private extension WalletManagerFactory {
    func makeWalletManager(
        wallet: Wallet,
        pairPublicKey: Data? = nil
    ) throws -> WalletManager {
        let blockchain = wallet.blockchain

        let networkInput = NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: blockchainSdkKeysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfiguration
        )

        let input = WalletManagerAssemblyInput(
            wallet: wallet,
            pairPublicKey: pairPublicKey,
            blockchainSdkDependencies: dependencies,
            networkInput: networkInput
        )

        return try blockchain.assembly.make(with: input)
    }
}

// MARK: - Stub Implementation

public extension WalletManagerFactory {
    /// Use this method only Test and Debug [Addresses, Fees, etc.]
    /// - Parameters:
    ///   - blockhain Card native blockchain will be used
    ///   - walletPublicKey: Wallet public key or dummy input
    ///   - addresses: Dummy input addresses
    /// - Returns: WalletManager model
    func makeStubWalletManager(
        blockchain: Blockchain,
        dummyPublicKey: Data,
        dummyAddress: String
    ) throws -> WalletManager { let publicKey = Wallet.PublicKey(seedKey: dummyPublicKey, derivationType: .none)
        let address: Address

        if dummyAddress.isEmpty {
            let service = AddressServiceFactory(blockchain: blockchain).makeAddressService()
            address = try service.makeAddress(for: publicKey, with: .default)
        } else {
            address = PlainAddress(value: dummyAddress, publicKey: publicKey, type: .default)
        }

        let wallet = Wallet(blockchain: blockchain, addresses: [.default: address])

        let networkInput = NetworkProviderAssembly.Input(
            blockchain: blockchain,
            keysConfig: blockchainSdkKeysConfig,
            apiInfo: apiList[blockchain.networkId] ?? [],
            tangemProviderConfig: tangemProviderConfiguration
        )

        let input = WalletManagerAssemblyInput(
            wallet: wallet,
            pairPublicKey: nil,
            blockchainSdkDependencies: dependencies,
            networkInput: networkInput
        )

        return try blockchain.assembly.make(with: input)
    }
}
