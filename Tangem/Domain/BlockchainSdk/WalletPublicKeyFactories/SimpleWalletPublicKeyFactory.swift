//
//  SimpleWalletPublicKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SimpleWalletPublicKeyFactory: AnyWalletPublicKeyFactory {
    func makePublicKey(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet.PublicKey {
        let blockchain = blockchainNetwork.blockchain

        guard let walletPublicKey = keys.first(where: { $0.curve == blockchain.curve })?.publicKey else {
            throw CommonError.noData
        }

        return Wallet.PublicKey(seedKey: walletPublicKey, derivationType: .none)
    }
}
