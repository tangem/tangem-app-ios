//
//  AnyWalletPublicKeyFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

protocol AnyWalletPublicKeyFactory {
    func makePublicKey(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet.PublicKey
}
