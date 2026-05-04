//
//  AlephiumInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct AlephiumInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .alephium = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let networkService: AlephiumNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let accountInfo = try await networkService.getAccountInfo(for: address).async()

        let utils = AlephiumUtils()
        let filteredUTXO = accountInfo.utxo.filter { utils.isNotFromFuture(lockTime: Double($0.lockTime)) }

        let nativeSum = filteredUTXO.map(\.value).reduce(Decimal.zero, +)
        let nativeBalance = nativeSum / blockchain.decimalValue

        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
