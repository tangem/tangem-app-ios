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
        let filteredBlockchains = supportedBlockchains.filter {
            MoralisSupportedBlockchains.networkIds.contains($0.networkId)
        }

        var result: [NetworkAddressPair] = []
        var skippedCount = 0

        for blockchain in filteredBlockchains {
            switch blockchain {
            case .hedera:
                skippedCount += 1
                continue
            case .chia:
                skippedCount += 1
                continue
            default:
                break
            }

            do {
                let pair = try walletAddressResolver.resolveAddress(for: blockchain, keyInfos: keyInfos)
                result.append(pair)
            } catch {
                skippedCount += 1
            }
        }

        AppLogger.info(
            "InitialWalletTokenSyncAddressResolver: resolved \(result.count)/\(filteredBlockchains.count) addresses, skipped \(skippedCount)"
        )

        return result
    }
}
