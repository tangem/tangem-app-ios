//
//  LegacyLockingScriptBuilderTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

class LegacyLockingScriptBuilderTests {
    @Test
    func dogecoin() throws {
        // given
        let builder = Base58Decoder.dogecoin()

        // when
        let p2pkh = try builder.lockingScript(for: "DR45C6m5aWgBn4QotLghcwDSAJyEL8uz4m")
        let p2sh = try builder.lockingScript(for: "9ypUW9wok6Q3djFEbLeUyXp7D6arVLeaA2")

        // then
        #expect(p2pkh.data == Data(hexString: "76a914da6f4f9c8dcf80f33ed5d06c45c4fc5fedeb384888ac"))
        #expect(p2sh.data == Data(hexString: "a91450fbea73f805b2524d2d38c3c8f72c898c44d02f87"))

        #expect(p2pkh.type == .p2pkh)
        #expect(p2sh.type == .p2sh)
    }

    // [REDACTED_TODO_COMMENT]
    // Dash
    // Ravencoin
    // Ducatus
    // Clore
    // Radiant

}
