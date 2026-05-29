//
//  ContractAddressResolverFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct ContractAddressResolverFactory {
    private let blockchain: Blockchain
    private let blockchainSdkKeysConfig: BlockchainSdkKeysConfig
    private let providerConfiguration: TangemProviderConfiguration
    private let apiList: APIList

    public init(
        blockchain: Blockchain,
        blockchainSdkKeysConfig: BlockchainSdkKeysConfig,
        providerConfiguration: TangemProviderConfiguration = .ephemeralConfiguration,
        apiList: APIList
    ) {
        self.blockchain = blockchain
        self.blockchainSdkKeysConfig = blockchainSdkKeysConfig
        self.providerConfiguration = providerConfiguration
        self.apiList = apiList
    }

    public func makeResolver() throws -> ContractAddressResolver {
        switch blockchain {
        case .hedera(_, let testnet):
            return HederaContractAddressResolver(
                isTestnet: testnet,
                networkService: try makeHederaNetworkService()
            )
        default:
            return CommonContractAddressResolver()
        }
    }
}

private extension ContractAddressResolverFactory {
    func makeHederaNetworkService() throws -> HederaNetworkService {
        let serviceFactory = WalletNetworkServiceFactory(
            blockchainSdkKeysConfig: blockchainSdkKeysConfig,
            tangemProviderConfig: providerConfiguration,
            apiList: apiList
        )

        return try serviceFactory.makeServiceWithType(for: blockchain)
    }
}
