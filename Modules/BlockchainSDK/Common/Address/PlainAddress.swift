//
//  PlainAddress.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct PlainAddress: Address {
    public let value: String
    public let publicKey: Wallet.PublicKey
    public let type: AddressType

    public var localizedName: String { type.defaultLocalizedName }

    public init(value: String, publicKey: Wallet.PublicKey, type: AddressType) {
        self.value = value
        self.publicKey = publicKey
        self.type = type
    }
}
