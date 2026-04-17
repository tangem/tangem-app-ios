//
//  ChiaInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct ChiaInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .chia = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let networkService: ChiaNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let puzzleHash = try ChiaPuzzleUtils().getPuzzleHash(from: address).hex()
        let coins = try await networkService.getUnspents(puzzleHash: puzzleHash).async()
        let nativeBalance = coins.map { Decimal(string: String($0.amount)) ?? .zero }.reduce(0, +) / blockchain.decimalValue

        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
