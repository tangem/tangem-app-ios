//
//  CardanoInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct CardanoInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .cardano = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let networkService: CardanoNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let response = try await networkService.getInfo(addresses: [address], tokens: []).async()
        let balanceDecimal = Decimal(string: String(response.balance)) ?? .zero
        let nativeBalance = balanceDecimal / blockchain.decimalValue

        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
