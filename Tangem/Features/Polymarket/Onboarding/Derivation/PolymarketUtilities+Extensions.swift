//
//  PolymarketUtilities+Extensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket
import TangemSdk

extension PolymarketUtilities {
    static var blockchain: Blockchain {
        .polygon(testnet: false)
    }

    static func makeAddress(using walletPublicKey: Wallet.PublicKey) throws -> String {
        try AddressServiceFactory(blockchain: blockchain)
            .makeAddressService()
            .makeAddress(for: walletPublicKey, with: .default)
            .value
    }

    static func makePublicKey(seedKey: Data, derivedKey: ExtendedPublicKey) -> Wallet.PublicKey {
        Wallet.PublicKey(
            seedKey: seedKey,
            derivationType: .plain(.init(path: derivationPath, extendedPublicKey: derivedKey))
        )
    }

    static func getKey(from repository: KeysRepository) -> Wallet.PublicKey? {
        guard
            let masterKey = try? repository.masterKey(curve: mandatoryCurve),
            let publicKey = masterKey.publicKey,
            let derivedKey = masterKey.derivedKeys[derivationPath]
        else {
            return nil
        }

        return makePublicKey(seedKey: publicKey, derivedKey: derivedKey)
    }
}
