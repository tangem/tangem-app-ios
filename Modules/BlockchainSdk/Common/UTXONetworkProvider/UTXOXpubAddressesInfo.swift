//
//  UTXOXpubAddressesInfo.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct UTXOXpubAddressesInfo {
    let addresses: [Address]
}

extension UTXOXpubAddressesInfo {
    struct Address {
        let usedAddress: UTXOUsedAddress
        let transfers: Int
        let balance: Decimal

        var isUsed: Bool { transfers > 0 }
    }
}

public struct UTXOUsedAddress: Hashable {
    public let address: String
    public let derivationPath: DerivationPath
    public let scriptType: UTXOXpubScriptType

    init(address: String, derivationPath: DerivationPath, scriptType: UTXOXpubScriptType) {
        self.address = address
        self.derivationPath = derivationPath
        self.scriptType = scriptType
    }
}
