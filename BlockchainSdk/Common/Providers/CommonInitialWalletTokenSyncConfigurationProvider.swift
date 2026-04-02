//
//  CommonInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct CommonInitialWalletTokenSyncConfigurationProvider: InitialWalletTokenSyncConfigurationProvider {
    // MARK: - Private Properties

    private let networkServiceFactory: WalletNetworkServiceFactory

    // MARK: - Init

    public init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    public func canHandle(_ blockchain: Blockchain) -> Bool {
        switch blockchain {
        case .solana, .xrp:
            return true
        default:
            return false
        }
    }

    public func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        // [REDACTED_TODO_COMMENT]
        return InitialWalletTokenSyncConfiguration(nativeBalance: 0, tokens: [])
    }
}
