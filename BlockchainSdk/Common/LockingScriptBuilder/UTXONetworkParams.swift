//
//  UTXONetworkParams.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol UTXONetworkParams {
    var p2pkh: UInt8 { get }
    var p2sh: UInt8 { get }
    var bech32: String { get }
}
