//
//  LockingScriptAddress.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct LockingScriptAddress: Address {
    public let value: String
    public let publicKey: Wallet.PublicKey
    public let type: AddressType
    public let lockingScript: UTXOLockingScript

    public var localizedName: String { type.defaultLocalizedName }

    public init(value: String, publicKey: Wallet.PublicKey, type: AddressType, lockingScript: UTXOLockingScript) {
        self.value = value
        self.publicKey = publicKey
        self.type = type
        self.lockingScript = lockingScript
    }
}
