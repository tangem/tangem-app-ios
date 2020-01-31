//
//  LitecoinAddressValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class LitecoinAddressValidator: BitcoinAddressValidator {
    override var possibleFirstCharacters: [String] {
        ["l","m"]
    }
}
