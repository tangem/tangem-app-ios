//
//  LegacyLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import BlockchainSdk

class LegacyLockingScriptBuilderTests {
    @Test
    func dogecoin() throws {
        // given
        let builder = Base58LockingScriptBuilder.dogecoin()

        // when
        let p2pkh = try builder.lockingScript(for: "D6UCu5YJ2PvokfvgnBZP1kG1Cb43m7yhyp")

        // then
        #expect(p2pkh.data == Data(hexString: "76a9140e955656f1913005257fb0a8a8828bd90f2dd98688ac"))
        #expect(p2pkh.type == .p2pkh)
    }

    @Test
    func dash() throws {
        // given
        let builder = Base58LockingScriptBuilder.dash(isTestnet: false)

        // when
        let p2pkh = try builder.lockingScript(for: "XdspNeStZQb3SmCtH97nbqypxZYVPTaYgm")

        // then
        #expect(p2pkh.data == Data(hexString: "76a91422fbbc3858bf8fcef42fd42d67ad6b29de88224f88ac"))
        #expect(p2pkh.type == .p2pkh)
    }

    @Test
    func ravencoin() throws {
        // given
        let builder = Base58LockingScriptBuilder.ravencoin(isTestnet: false)

        // when
        let p2pkh = try builder.lockingScript(for: "RMcnB1FZdmrvo2yTFnuaHWbAWZhdw4acxq")

        // then
        #expect(p2pkh.data == Data(hexString: "76a9148755df9a7c0e702c84508e0cca7a0581a141068588ac"))
        #expect(p2pkh.type == .p2pkh)
    }

    @Test
    func clore() throws {
        // given
        let builder = Base58LockingScriptBuilder.clore()

        // when
        let p2pkh = try builder.lockingScript(for: "APdoRDNw2abAWGgaFdMep6LSUFjQ3jhRUd")

        // then
        #expect(p2pkh.data == Data(hexString: "76a914563a25fa8cc175cc6b8c8ef71b3a4e9088fc0fb688ac"))
        #expect(p2pkh.type == .p2pkh)
    }

    @Test
    func radiant() throws {
        // given
        let builder = Base58LockingScriptBuilder.radiant()

        // when
        let p2pkh = try builder.lockingScript(for: "16v8fwe1XmuMnMr7ZBKy3EN2mDWiMJBxXU")

        // then
        #expect(p2pkh.data == Data(hexString: "76a91440e5142395b2fa7c0ca376ba5476fb7ba3a5112b88ac"))
        #expect(p2pkh.type == .p2pkh)
    }
}
