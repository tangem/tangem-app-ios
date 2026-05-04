//
//  KaspaInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct KaspaInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        guard case .kaspa = blockchain else {
            throw BlockchainSdkError.notImplemented
        }

        let infoService: KaspaNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)
        let lockingScriptBuilder: KaspaAddressLockingScriptBuilder = .kaspa()
        let lockingScript = try lockingScriptBuilder.lockingScript(for: address)
        let lockingScriptAddress = LockingScriptAddress(value: address, type: .default, lockingScript: lockingScript)
        let unspentOutputManager: CommonUnspentOutputManager = .kaspa(address: lockingScriptAddress)

        let responses = try await infoService.getInfo(addresses: [lockingScriptAddress]).async()

        responses.forEach { response in
            unspentOutputManager.update(outputs: response.response.outputs, for: response.address)
        }

        let nativeBalance = unspentOutputManager.balance(blockchain: blockchain)
        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
    }
}
