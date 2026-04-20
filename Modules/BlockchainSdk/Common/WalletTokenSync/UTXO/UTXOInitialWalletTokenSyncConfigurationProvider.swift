//
//  UTXOInitialWalletTokenSyncConfigurationProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct UTXOInitialWalletTokenSyncConfigurationProvider {
    private let networkServiceFactory: WalletNetworkServiceFactory

    init(networkServiceFactory: WalletNetworkServiceFactory) {
        self.networkServiceFactory = networkServiceFactory
    }

    func configuration(
        for blockchain: Blockchain,
        address: String
    ) async throws -> InitialWalletTokenSyncConfiguration {
        let infoService = try makeInfoService(for: blockchain)
        let lockingScriptBuilder = try makeLockingScriptBuilder(for: blockchain)
        let lockingScript = try lockingScriptBuilder.lockingScript(for: address)
        let lockingScriptAddress = LockingScriptAddress(value: address, type: .default, lockingScript: lockingScript)
        let unspentOutputManager = try makeUnspentOutputManager(blockchain: blockchain)

        let responses = try await infoService.getInfo(addresses: [lockingScriptAddress]).async()

        responses.forEach { response in
            unspentOutputManager.update(outputs: response.response.outputs, for: response.address)
        }

        let nativeBalance = unspentOutputManager.balance(blockchain: blockchain)
        return InitialWalletTokenSyncConfiguration(nativeBalance: nativeBalance, tokens: [])
    }

    private func makeInfoService(for blockchain: Blockchain) throws -> UTXONetworkAddressInfoProvider {
        switch blockchain {
        case .bitcoin:
            let netwworkService: BitcoinNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

            return netwworkService
        case .litecoin:
            let netwworkService: LitecoinNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

            return netwworkService
        case .bitcoinCash:
            let netwworkService: BitcoinCashNetworkService = try networkServiceFactory.makeServiceWithType(for: blockchain)

            return netwworkService
        case .dogecoin,
             .dash,
             .ravencoin,
             .ducatus,
             .radiant,
             .clore,
             .fact0rn,
             .pepecoin:
            let networkService: MultiUTXONetworkProvider = try networkServiceFactory.makeServiceWithType(for: blockchain)

            return networkService
        default:
            throw BlockchainSdkError.notImplemented
        }
    }

    private func makeLockingScriptBuilder(for blockchain: Blockchain) throws -> LockingScriptBuilder {
        switch blockchain {
        case .bitcoin:
            return .bitcoin(isTestnet: blockchain.isTestnet)
        case .litecoin:
            return .litecoin()
        case .bitcoinCash:
            return .bitcoinCash(isTestnet: blockchain.isTestnet)
        case .dogecoin:
            return .dogecoin()
        case .dash:
            return .dash(isTestnet: blockchain.isTestnet)
        case .ravencoin:
            return .ravencoin(isTestnet: blockchain.isTestnet)
        case .ducatus:
            return .ducatus()
        case .clore:
            return .clore()
        case .pepecoin:
            return .pepecoin(isTestnet: blockchain.isTestnet)
        case .radiant:
            return .radiant()
        case .fact0rn:
            return .fact0rn()
        default:
            throw BlockchainSdkError.notImplemented
        }
    }

    private func makeUnspentOutputManager(blockchain: Blockchain) throws -> UnspentOutputManager {
        switch blockchain {
        case .bitcoin:
            return .bitcoin(isTestnet: blockchain.isTestnet)
        case .litecoin:
            return .litecoin()
        case .bitcoinCash:
            return .bitcoinCash(isTestnet: blockchain.isTestnet)
        case .dogecoin:
            return .dogecoin()
        case .dash:
            return .dash(isTestnet: blockchain.isTestnet)
        case .ravencoin:
            return .ravencoin(isTestnet: blockchain.isTestnet)
        case .ducatus:
            return .ducatus()
        case .clore:
            return .clore()
        case .pepecoin:
            return .pepecoin(isTestnet: blockchain.isTestnet)
        case .radiant:
            return .radiant()
        case .fact0rn:
            return .fact0rn()
        default:
            throw BlockchainSdkError.notImplemented
        }
    }
}
