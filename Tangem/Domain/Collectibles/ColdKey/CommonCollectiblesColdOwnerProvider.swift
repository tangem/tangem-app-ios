//
//  CommonCollectiblesColdOwnerProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import BlockchainSdk
import TangemSdk

/// The vault is addressed off this key, so it must be the account's own derivation — the main account's key
/// would address a different vault and put spendable funds behind the same signature.
final class CommonCollectiblesColdOwnerProvider {
    private let keysRepository: KeysRepository
    private let derivationStyle: DerivationStyle?

    init(keysRepository: KeysRepository, derivationStyle: DerivationStyle?) {
        self.keysRepository = keysRepository
        self.derivationStyle = derivationStyle
    }
}

// MARK: - CollectiblesColdOwnerProvider protocol conformance

extension CommonCollectiblesColdOwnerProvider: CollectiblesColdOwnerProvider {
    func coldOwnerKey() -> Wallet.PublicKey? {
        let path = CollectiblesAccountKeyPath.derivationPath

        let curve = CollectiblesAccountKeyPath.curve(for: derivationStyle)

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
