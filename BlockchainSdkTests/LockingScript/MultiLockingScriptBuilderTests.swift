//
//  MultiLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class MultiLockingScriptBuilderTests {
    @Test
    func p2pkh() throws {
        // given
        let builder = MultiLockingScriptBuilder.bitcoin(isTestnet: false)

        // when
        let script = try builder.lockingScript(for: "12higDjoCCNXSA95xZMWUdPvXNmkAduhWv")

        // then
        #expect(script.data == Data(hexString: "76a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac"))
        #expect(script.type == .p2pkh)
    }

    @Test
    func p2sh() throws {
        // given
        let builder = MultiLockingScriptBuilder.bitcoin(isTestnet: false)

        // when
        let script = try builder.lockingScript(for: "342ftSRCvFHfCeFFBuz4xwbeqnDw6BGUey")

        // then
        #expect(script.data == Data(hexString: "a91419a7d869032368fd1f1e26e5e73a4ad0e474960e87"))
        #expect(script.type == .p2sh)
    }

    @Test
    func p2wpkh() throws {
        // given
        let builder = MultiLockingScriptBuilder.bitcoin(isTestnet: false)

        // when
        let script = try builder.lockingScript(for: "bc1q34aq5drpuwy3wgl9lhup9892qp6svr8ldzyy7c")

        // then
        #expect(script.data == Data(hexString: "00148d7a0a3461e3891723e5fdf8129caa0075060cff"))
        #expect(script.type == .p2wpkh)
    }

    @Test
    func p2wsh() throws {
        // given
        let builder = MultiLockingScriptBuilder.bitcoin(isTestnet: false)

        // when
        let script = try builder.lockingScript(for: "bc1qeklep85ntjz4605drds6aww9u0qr46qzrv5xswd35uhjuj8ahfcqgf6hak")

        // then
        #expect(script.data == Data(hexString: "0020cdbf909e935c855d3e8d1b61aeb9c5e3c03ae8021b286839b1a72f2e48fdba70"))
        #expect(script.type == .p2wsh)
    }

    @Test
    func p2tr() throws {
        // given
        let builder = MultiLockingScriptBuilder.bitcoin(isTestnet: false)

        // when
        let script = try builder.lockingScript(for: "bc1pxwww0ct9ue7e8tdnlmug5m2tamfn7q06sahstg39ys4c9f3340qqxrdu9k")

        // then
        #expect(script.data == Data(hexString: "5120339ce7e165e67d93adb3fef88a6d4beed33f01fa876f05a225242b82a631abc0"))
        #expect(script.type == .p2tr)
    }
}
