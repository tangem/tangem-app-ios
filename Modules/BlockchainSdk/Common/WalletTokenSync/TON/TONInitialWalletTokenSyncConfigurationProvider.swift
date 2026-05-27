//
//  TONInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TONInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    // MARK: - InitialWalletTokenSyncConfigurationProvider

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .ton = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let tonNetworkService: TONNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let info = try await tonNetworkService.getInfo(address: address, tokens: []).async()

        return InitialWalletTokenSyncConfiguration(nativeBalance: info.balance, tokens: [])
    }
}
