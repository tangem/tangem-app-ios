//
//  InitialWalletTokenSyncAddressResolver.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemFoundation

struct InitialWalletTokenSyncAddressResolver: InitialWalletTokenSyncAddressResolving {
    private let walletAddressResolver = WalletAddressResolver()

    func resolve(
        keyInfos: [KeyInfo],
        supportedBlockchains: Set<Blockchain>
    ) -> [NetworkAddressPair] {
        let filteredBlockchains = supportedBlockchains.intersection(MoralisSupportedBlockchains.all)

        var result: [NetworkAddressPair] = []

        for blockchain in filteredBlockchains {
            do {
                let pair = try walletAddressResolver.resolveAddress(for: blockchain, keyInfos: keyInfos)
                result.append(pair)
            } catch {
                AppLogger.tag("InitialWalletTokenSyncAddressResolver").warning("Failed to resolve address for \(blockchain.networkId): \(error)")
            }
        }

        AppLogger.tag("InitialWalletTokenSyncAddressResolver").info("Resolved \(result.count)/\(filteredBlockchains.count) addresses")

        return result
    }
}
