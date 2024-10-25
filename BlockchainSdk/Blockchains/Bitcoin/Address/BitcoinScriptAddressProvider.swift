//
//  BitcoinScriptAddressProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol BitcoinScriptAddressProvider {
    func makeScriptAddress(from scriptHash: Data) throws -> String
}
