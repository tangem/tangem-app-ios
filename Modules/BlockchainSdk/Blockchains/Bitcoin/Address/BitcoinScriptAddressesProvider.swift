//
//  BitcoinScriptAddressesProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol BitcoinScriptAddressesProvider {
    func makeAddresses(publicKey: Wallet.PublicKey, pairPublicKey: Data) throws -> [LockingScriptAddress]
}
