//
//  LitecoinAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public class LitecoinAddressFactory: BitcoinAddressFactory {
    override func getNetwork(_ testnet: Bool) -> Data {
        return Data([UInt8(30)])
    }
}
