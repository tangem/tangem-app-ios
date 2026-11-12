//
//  StringDroppingNetworkSuffixTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Testing
@testable import Tangem

@Suite("Network name placed into a phrase that already says network")
struct StringDroppingNetworkSuffixTests {
    @Test(
        "The trailing network word is dropped from the name",
        arguments: [
            (Blockchain.xdc(testnet: false), "XDC"),
            (.areon(testnet: false), "Areon"),
            (.areon(testnet: true), "Areon Testnet"),
            (.quai(testnet: false), "Quai"),
        ]
    )
    func networkSuffixIsDropped(blockchain: Blockchain, expected: String) {
        #expect(blockchain.displayName.droppingNetworkSuffix == expected)
    }

    @Test("A name without the network suffix stays as it is", arguments: ["Ethereum", "BNB Smart Chain", "Quai Orchard Testnet", "Networkcoin", "Network Chain", "Open Network Chain"])
    func nameWithoutNetworkSuffixIsKept(name: String) {
        #expect(name.droppingNetworkSuffix == name)
    }
}
