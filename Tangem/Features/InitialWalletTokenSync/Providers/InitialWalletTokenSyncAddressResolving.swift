//
//  InitialWalletTokenSyncAddressResolving.swift
//  Tangem
//
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

protocol InitialWalletTokenSyncAddressResolving {
    func resolve(
        keyInfos: [KeyInfo],
        supportedBlockchains: Set<Blockchain>
    ) -> [NetworkAddressPair]
}
