//
//  DucatusAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public class DucatusAddressFactory: BitcoinAddressFactory {
    override func getNetwork(_ testnet: Bool) -> Data {
        return Data([UInt8(31)])
    }
}
