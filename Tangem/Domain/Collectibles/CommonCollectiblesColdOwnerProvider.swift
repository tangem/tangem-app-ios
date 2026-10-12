//
//  CommonCollectiblesColdOwnerProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

/// The vault is addressed off this key, so it must be the account's own derivation — the main account's key
/// would address a different vault and put spendable funds behind the same signature.
///
/// Holding the config is safe here although it is replaceable: the curve follows the wallet's generation,
/// and no live wallet crosses generations — the upgrade that swaps the config is v3 on both sides.
final class CommonCollectiblesColdOwnerProvider {
    private let keysRepository: KeysRepository
    private let config: UserWalletConfig

    init(keysRepository: KeysRepository, config: UserWalletConfig) {
        self.keysRepository = keysRepository
        self.config = config
    }
}

// MARK: - CollectiblesColdOwnerProvider protocol conformance

extension CommonCollectiblesColdOwnerProvider: CollectiblesColdOwnerProvider {
    func coldOwnerKey() -> Wallet.PublicKey? {
        let path = CollectiblesAccountKeyPath.derivationPath

        let curve = CollectiblesAccountKeyPath.curve(for: config)

        guard
            let masterKey = try? keysRepository.masterKey(curve: curve),
            let seedKey = masterKey.publicKey,
            let derivedKey = masterKey.derivedKeys[path]
        else {
            return nil
        }

        return Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .plain(.init(path: path, extendedPublicKey: derivedKey))
        )
    }
}
