//
//  AnyWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Puts together the `Wallet` a manager is then built around: the key the wallet signs with and, derived from it,
/// the addresses its funds live at.
protocol AnyWalletFactory {
    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet
}

enum AnyWalletFactoryError: Error {
    case entryHasNotDerivationPath
    case noDerivation
    case walletWithBlockchainCurveNotFound
    case twinWalletPublicKeyNotFound
    /// The account keeps everything at one address of its own and has not been given it yet.
    case accountAddressUnavailable
}
