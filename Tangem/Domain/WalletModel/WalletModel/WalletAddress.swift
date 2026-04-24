//
//  WalletAddress.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct WalletAddress {
    let value: String
    let localizedName: String

    init(value: String, localizedName: String) {
        self.value = value
        self.localizedName = localizedName
    }
}

struct WalletAddressBuilder {
    private let wallet: Wallet

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    func build() -> [WalletAddress] {
        let addresses = wallet.addresses.filter { !$0.type.isUsed }

        return addresses.map { address in
            WalletAddress(
                value: address.value,
                localizedName: address.localizedName
            )
        }
    }
}
