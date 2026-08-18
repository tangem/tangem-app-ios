//
//  PolymarketUtilitiesTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import TangemPolymarket

@Suite("PolymarketUtilities")
struct PolymarketUtilitiesTests {
    @Test("The owner path is pinned")
    func ownerPathIsPinned() {
        #expect(PolymarketUtilities.derivationPath.rawPath == "m/44'/60'/999997'/0/0")
    }

    @Test("The owner key lives on secp256k1")
    func ownerCurveIsPinned() {
        #expect(PolymarketUtilities.mandatoryCurve == .secp256k1)
    }
}
