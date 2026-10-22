//
//  CollectiblesAccountKeyPathTests.swift
//  TangemCollectiblesTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemSdk
import Testing
@testable import TangemCollectibles

@Suite("CollectiblesAccountKeyPath")
struct CollectiblesAccountKeyPathTests {
    @Test("The derivation path is the fixed contract path")
    func derivationPathIsTheContractPath() throws {
        let contractPath = try DerivationPath(rawPath: "m/44'/501'/999799'/0'/0'")

        #expect(CollectiblesAccountKeyPath.derivationPath == contractPath)
    }

    @Test("Legacy and unknown derivation styles use plain ed25519")
    func legacyStylesUsePlainEd25519() {
        for derivationStyle in [DerivationStyle?.none, .v1, .v2] {
            #expect(CollectiblesAccountKeyPath.curve(for: derivationStyle) == .ed25519, "\(String(describing: derivationStyle))")
        }
    }

    @Test("The Wallet 2 derivation style uses slip0010 ed25519")
    func wallet2StyleUsesSlip0010Ed25519() {
        #expect(CollectiblesAccountKeyPath.curve(for: .v3) == .ed25519_slip0010)
    }
}
