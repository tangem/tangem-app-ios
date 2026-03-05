//
//  AddressResolverFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct AddressResolverFactory {
    // MARK: - Private Properties

    private let blockchainSdkKeysConfig: BlockchainSdkKeysConfig
    private let tangemProviderConfig: TangemProviderConfiguration
    private let apiList: APIList

    private var walletNetworkServiceFactory: WalletNetworkServiceFactory {
        WalletNetworkServiceFactory(
            blockchainSdkKeysConfig: blockchainSdkKeysConfig,
            tangemProviderConfig: tangemProviderConfig,
            apiList: apiList
        )
    }

    // MARK: - Init

    public init(
        blockchainSdkKeysConfig: BlockchainSdkKeysConfig,
        tangemProviderConfig: TangemProviderConfiguration,
        apiList: APIList
    ) {
        self.apiList = apiList
        self.blockchainSdkKeysConfig = blockchainSdkKeysConfig
        self.tangemProviderConfig = tangemProviderConfig
    }

    public func makeAddressResolver(for blockchain: Blockchain) -> AddressResolver? {
        try? makeAddressResolverWithType(for: blockchain)
    }

    public func makeAddressResolverWithType(for blockchain: Blockchain) throws -> AddressResolver {
        switch blockchain {
        case .ethereum:
            let networkService: EthereumNetworkService = try walletNetworkServiceFactory.makeServiceWithType(for: blockchain)
            return EthereumAddressResolver(networkService: networkService, ensProcessor: CommonENSProcessor())
        case .near:
            let networkService: NEARNetworkService = try walletNetworkServiceFactory.makeServiceWithType(for: blockchain)
            return NEARAddressResolver(networkService: networkService)
        case .xrp:
            let networkService: XRPNetworkService = try walletNetworkServiceFactory.makeServiceWithType(for: blockchain)
            return XRPAddressResolver(networkService: networkService)
        case .stellar:
            let networkService: StellarNetworkService = try walletNetworkServiceFactory.makeServiceWithType(for: blockchain)
            return StellarAddressResolver(networkService: networkService)
        default:
            throw BlockchainSdkError.notImplemented
        }
    }
}
