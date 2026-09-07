//
//  JointWalletFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Builds the wallet of a joint account, whose tokens all live at the one address its contract was given
/// instead of at an address derived from the key.
struct JointWalletFactory: AnyWalletFactory {
    private let defaultWalletFactory: any AnyWalletFactory
    private let safeAddress: String?

    init(defaultWalletFactory: any AnyWalletFactory, safeAddress: String?) {
        self.defaultWalletFactory = defaultWalletFactory
        self.safeAddress = safeAddress
    }

    func makeWallet(blockchainNetwork: BlockchainNetwork, keys: [KeyInfo]) throws -> Wallet {
        guard let safeAddress else {
            throw AnyWalletFactoryError.accountAddressUnavailable
        }

        // The key stays the one this member signs the account's operations with — only where the funds live differs
        let publicKey = try defaultWalletFactory.makeWallet(blockchainNetwork: blockchainNetwork, keys: keys).publicKey
        let addressesProvider = CommonAddressesProvider(defaultAddress: PlainAddress(value: safeAddress, type: .default))

        return Wallet(
            blockchain: blockchainNetwork.blockchain,
            publicKey: publicKey,
            addressesProvider: addressesProvider
        )
    }
}
