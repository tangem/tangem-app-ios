//
//  SegWitDecoderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class SegWitDecoderTests {
    @Test
    func p2pkh() async throws {
        // given
        let address = "ltc1qw508d6qejxtdg4y5r3zarvary0c5xw7kg3g4ty"

        // when
        let script = try SegWitDecoder(network: LitecoinNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "0014751e76e8199196d454941c45d1b3a323f1433bd6")
        #expect(script.type == .p2wpkh)
    }

    @Test
    func p2sh() async throws {
        // given
        let address = "ltc1qrp33g0q5vnjqgy55s7tvj2mklp8ynjzsc8sfk0"

        // when
        let script = try SegWitDecoder(network: LitecoinNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "0020c3a1b3a7ce01ab0d3e2339cc8e4e04a3b6af600bcf3f175b0c2a83a1d1e926fd")
        #expect(script.type == .p2wsh)
    }
}
