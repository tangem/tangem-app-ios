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
    // MARK: - Bitcoin Cash

    @Test
    func bitcoinCash_p2pkh() async throws {
        // given
        let address = "bitcoincash:qrarm7ydhnluysgcjjka8uc9jmw8ujz605f4uwhl8d"

        // when
        let script = try CashAddrDecoder(network: BitcoinCashNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "76a914fa3df88dbcffc2411894add3f30596dc7e485a7d88ac")
        #expect(script.type == .p2pkh)
    }

    @Test
    func bitcoinCash_p2sh() async throws {
        // given
        let address = "bitcoincash:pzvxjpc2tzkc54hwsguk6mnxk592l3gdz55n7qj2tw"

        // when
        let script = try CashAddrDecoder(network: BitcoinCashNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "a9149869070a58ad8a56ee82396d6e66b50aafc50d1587")
        #expect(script.type == .p2sh)
    }

    // MARK: - Kaspa

    @Test
    func kaspa_p2pkh() async throws {
        // given
        let address = "kaspa:qppsc4tz6z5rz6ax32j3w6tr2xkqsk9w4vpsv0tzczgw7"

        // when
        let script = try CashAddrDecoder(network: KaspaNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "2103a34b8f598ccd43a8ff4f8d28b1e9a72213f6e4d4b530376ffa0c5f6d97e2b9aac")
        #expect(script.type == .p2pkh)
    }

    @Test
    func kaspa_p2sh() async throws {
        // given
        let address = "kaspa:qzl6exm9sjv9gxpy5fn2f74w3qf8skl7jywnqdrwt0n9z"

        // when
        let script = try CashAddrDecoder(network: BitcoinCashNetworkParams()).lockingScript(for: address)

        // then

        #expect(script.data.hexString.lowercased() == "a9145f3b4a9c8e6f7d4f3e8b6b7c4a2d9c7b5a3f6c9887")
        #expect(script.type == .p2sh)
    }
}
