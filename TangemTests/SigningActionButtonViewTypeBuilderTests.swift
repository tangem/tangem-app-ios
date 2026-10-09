//
//  SigningActionButtonViewTypeBuilderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemUI
@testable import Tangem

@Suite("Tests for choosing how a signing button is confirmed")
struct SigningActionButtonViewTypeBuilderTests {
    private let builder = SigningActionButtonViewTypeBuilder()

    @Test("A wallet that taps a card confirms with a tap and the card logo")
    func cardWalletTaps() {
        #expect(builder.build(config: UserWalletConfigStub()) == .cardTap)
    }

    @Test("A wallet without NFC confirms by holding the button")
    func walletWithoutNFCHolds() {
        #expect(builder.build(config: UserWalletConfigStub(unavailableFeatures: [.nfcInteraction])) == .holdToConfirm)
    }
}
