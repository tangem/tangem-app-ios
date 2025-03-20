//
//  Base58DecoderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class Base58DecoderTests {
    @Test
    func p2pkh() async throws {
        // given
        let address = "LVt5dW2PqeyQn8dr5oGSPM9tKFHkDJxjtx"

        // when
        let script = try Base58Decoder(network: LitecoinNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "76a9141f9e3a16b862dfb8c54e742d07b4b46cc56b258388ac")
        #expect(script.type == .p2pkh)
    }

    @Test
    func p2sh() async throws {
        // given
        let address = "MQ5GzNtPtjH5YmV95rAQ9uShKNnpBnmUJn"

        // when
        let script = try Base58Decoder(network: LitecoinNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "a9142fb1e6b475ed75978f3fae2aaafaa10a818210f587")
        #expect(script.type == .p2sh)
    }
}
