//
//  KaspaLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

class KaspaLockingScriptBuilderTests {
    @Test
    func p2pkh() throws {
        // given
        let builder = KaspaAddressLockingScriptBuilder.kaspa()

        // when
        let p2pkSchnorr = try builder.lockingScript(for: "kaspa:qq85gcpx9zhytqamzhc0mv25fn0d40slrs4cj6hmh0lyelf67mwawuwt6c98l")
        let p2pkECDSA = try builder.lockingScript(for: "kaspa:qyp4scvsxvkrjxyq98gd4xedhgrqtmf78l7wl8p8p4j0mjuvpwjg5cqhy97n472")
        let p2sh = try builder.lockingScript(for: "kaspa:pqurku73qluhxrmvyj799yeyptpmsflpnc8pha80z6zjh6efwg3v2rrepjm5r")

        // then
        #expect(p2pkSchnorr.data == Data(hexString: "200f44602628ae4583bb15f0fdb1544cdedabe1f1c2b896afbbbfe4cfd3af6ddd7ac"))
        #expect(p2pkECDSA.data == Data(hexString: "2103586190332c39188029d0da9b2dba0605ed3e3ffcef9c270d64fdcb8c0ba48a60ab"))
        #expect(p2sh.data == Data(hexString: "aa20383b73d107f9730f6c24bc5293240ac3b827e19e0e1bf4ef16852beb297222c587"))

        #expect(p2pkSchnorr.type == .p2pk)
        #expect(p2pkECDSA.type == .p2pk)
        #expect(p2sh.type == .p2sh)
    }
}
