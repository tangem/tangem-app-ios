//
//  DomainNameAddressResolverFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct DomainNameAddressResolverFactory {
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

    public func makeAddressResolver(for blockchain: Blockchain) -> DomainNameAddressResolver? {
        switch blockchain {
        case .ethereum:
            guard let networkService: EthereumNetworkService = try? walletNetworkServiceFactory.makeServiceWithType(for: blockchain) else {
                return nil
            }

            return EthereumAddressResolver(networkService: networkService, ensProcessor: CommonENSProcessor())
        default:
            return nil
        }
    }
}
