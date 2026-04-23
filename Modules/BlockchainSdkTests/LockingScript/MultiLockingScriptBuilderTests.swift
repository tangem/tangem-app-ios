//
//  MultiLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

/// Base58(Legacy) p2pkh / p2sh
/// SegWit(Beach32) p2wpkh / p2wsh
/// SegWit(Beach32m) p2tr
class MultiLockingScriptBuilderTests {
    @Test
    func bitcoin() throws {
        // given
        let builder = MultiLockingScriptBuilder.bitcoin(isTestnet: false)

        // when
        let p2pkh = try builder.lockingScript(for: "12higDjoCCNXSA95xZMWUdPvXNmkAduhWv")
        let p2sh = try builder.lockingScript(for: "342ftSRCvFHfCeFFBuz4xwbeqnDw6BGUey")
        let p2wpkh = try builder.lockingScript(for: "bc1q34aq5drpuwy3wgl9lhup9892qp6svr8ldzyy7c")
        let p2wsh = try builder.lockingScript(for: "bc1qeklep85ntjz4605drds6aww9u0qr46qzrv5xswd35uhjuj8ahfcqgf6hak")
        let p2tr = try builder.lockingScript(for: "bc1pxwww0ct9ue7e8tdnlmug5m2tamfn7q06sahstg39ys4c9f3340qqxrdu9k")

        // then

        #expect(p2pkh.data == Data(hexString: "76a91412ab8dc588ca9d5787dde7eb29569da63c3a238c88ac"))
        #expect(p2sh.data == Data(hexString: "a91419a7d869032368fd1f1e26e5e73a4ad0e474960e87"))
        #expect(p2wpkh.data == Data(hexString: "00148d7a0a3461e3891723e5fdf8129caa0075060cff"))
        #expect(p2wsh.data == Data(hexString: "0020cdbf909e935c855d3e8d1b61aeb9c5e3c03ae8021b286839b1a72f2e48fdba70"))
        #expect(p2tr.data == Data(hexString: "5120339ce7e165e67d93adb3fef88a6d4beed33f01fa876f05a225242b82a631abc0"))

        #expect(p2pkh.type == .p2pkh)
        #expect(p2sh.type == .p2sh)
        #expect(p2wpkh.type == .p2wpkh)
        #expect(p2wsh.type == .p2wsh)
        #expect(p2tr.type == .p2tr)
    }

    @Test
    func litecoin() throws {
        // given
        let builder = MultiLockingScriptBuilder.litecoin()

        // when
        let p2pkh = try builder.lockingScript(for: "LReXwHqoDEfuZDYHbmfmhEwCrpR5BxMTvQ")
        let p2sh = try builder.lockingScript(for: "MEBSMNDh8wRUAu7N9cwbvMpDcW821XzNvW")
        let p2wpkh = try builder.lockingScript(for: "ltc1qhzjptwpym9afcdjhs7jcz6fd0jma0l0rc0e5yr")
        let p2wsh = try builder.lockingScript(for: "ltc1qytf26rwljwrlwqnfrpvqj7k7p3gxdgtqxggmle4tzcjxvj83w5hsddmlts")

        // then

        #expect(p2pkh.data == Data(hexString: "76a9144676d8e3d0bc3176dd0f65bfc2ef3239a9b7006d88ac"))
        #expect(p2sh.data == Data(hexString: "a91444e4ddb58499c682ed483f07424986e1bc061df187"))
        #expect(p2wpkh.data == Data(hexString: "0014b8a415b824d97a9c365787a581692d7cb7d7fde3"))
        #expect(p2wsh.data == Data(hexString: "002022d2ad0ddf9387f702691858097ade0c5066a1603211bfe6ab16246648f1752f"))

        #expect(p2pkh.type == .p2pkh)
        #expect(p2sh.type == .p2sh)
        #expect(p2wpkh.type == .p2wpkh)
        #expect(p2wsh.type == .p2wsh)
    }
}
