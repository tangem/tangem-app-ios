//
//  BittensorAddressTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
@testable import BlockchainSdk
import Testing

struct BittensorAddressTests {
    @Test
    func defaultAddressGeneration() throws {
        try PolkadotNetworkTesting.testSubstrateNetwork(
            .bittensor(curve: .ed25519),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )

        try PolkadotNetworkTesting.testSubstrateNetwork(
            .bittensor(curve: .ed25519_slip0010),
            publicKey: Keys.AddressesKeys.edKey,
            expectedAddress: "5FgMiSJeYLnFGEGonXrcY2ct2Dimod4vnT6h7Ys1Eiue9KxK"
        )
    }
}
