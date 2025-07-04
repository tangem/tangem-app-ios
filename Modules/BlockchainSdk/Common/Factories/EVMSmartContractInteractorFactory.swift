//
//  EVMSmartContractInteractorFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemNetworkUtils

public struct EVMSmartContractInteractorFactory {
    private let blockchainSdkKeysConfig: BlockchainSdkKeysConfig
    private let tangemProviderConfig: TangemProviderConfiguration

    public init(blockchainSdkKeysConfig: BlockchainSdkKeysConfig, tangemProviderConfig: TangemProviderConfiguration) {
        self.blockchainSdkKeysConfig = blockchainSdkKeysConfig
        self.tangemProviderConfig = tangemProviderConfig
    }

    public func makeInteractor(for blockchain: Blockchain, apiInfo: [NetworkProviderType]) throws -> EVMSmartContractInteractor {
        guard blockchain.isEvm else {
            throw FactoryError.invalidBlockchain
        }

        let networkAssembly = NetworkProviderAssembly()
        let networkService = EthereumNetworkService(
            decimals: blockchain.decimalCount,
            providers: networkAssembly.makeEthereumJsonRpcProviders(with: NetworkProviderAssembly.Input(
                blockchain: blockchain,
                keysConfig: blockchainSdkKeysConfig,
                apiInfo: apiInfo,
                tangemProviderConfig: tangemProviderConfig
            )),
            abiEncoder: WalletCoreABIEncoder()
        )

        return networkService
    }
}

extension EVMSmartContractInteractorFactory {
    enum FactoryError: String, LocalizedError {
        case invalidBlockchain

        var errorDescription: String? {
            rawValue
        }
    }
}
