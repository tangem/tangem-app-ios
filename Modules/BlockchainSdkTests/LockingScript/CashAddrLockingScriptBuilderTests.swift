//
//  BitcoinCashLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

class BitcoinCashLockingScriptBuilderTests {
    @Test
    func p2pkh() throws {
        // given
        let builder = CashAddrLockingScriptBuilder(network: BitcoinCashNetworkParams())

        // when
        let p2pkh = try builder.lockingScript(for: "bitcoincash:qrarm7ydhnluysgcjjka8uc9jmw8ujz605f4uwhl8d")
        let p2sh = try builder.lockingScript(for: "bitcoincash:pzvxjpc2tzkc54hwsguk6mnxk592l3gdz55n7qj2tw")

        // then
        #expect(p2pkh.data == Data(hexString: "76a914fa3df88dbcffc2411894add3f30596dc7e485a7d88ac"))
        #expect(p2sh.data == Data(hexString: "a9149869070a58ad8a56ee82396d6e66b50aafc50d1587"))

        #expect(p2pkh.type == .p2pkh)
        #expect(p2sh.type == .p2sh)
    }
}
