//
//  JoystreamAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct JoystreamAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        try PolkadotNetworkTesting.testSubstrateNetwork(
            .joystream(curve: .ed25519),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "j4UwGHUYcR4HH6qiZ4WJJPBKsYboMJWe6WPj8V6uKfo4Gnhbt"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .joystream(curve: .ed25519_slip0010),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "j4UwGHUYcR4HH6qiZ4WJJPBKsYboMJWe6WPj8V6uKfo4Gnhbt"
        )
    }
}
