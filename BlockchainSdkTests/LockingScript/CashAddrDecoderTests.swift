//
//  CashAddrDecoderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class CashAddrDecoderTests {
    @Test
    func p2pkh() async throws {
        // given
        let address = "bitcoincash:qrarm7ydhnluysgcjjka8uc9jmw8ujz605f4uwhl8d"

        // when
        let script = try CashAddrDecoder(network: BitcoinCashNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "76a914fa3df88dbcffc2411894add3f30596dc7e485a7d88ac")
        #expect(script.type == .p2pkh)
    }

    @Test
    func p2sh() async throws {
        // given
        let address = "bitcoincash:pzvxjpc2tzkc54hwsguk6mnxk592l3gdz55n7qj2tw"

        // when
        let script = try CashAddrDecoder(network: BitcoinCashNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "a9149869070a58ad8a56ee82396d6e66b50aafc50d1587")
        #expect(script.type == .p2sh)
    }
}
