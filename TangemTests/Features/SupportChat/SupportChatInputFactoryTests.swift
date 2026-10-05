//
//  SupportChatInputFactoryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

/// Usedesk keeps one conversation per client and matches it by the identifier it is handed, so a chat opened
/// by a link has to arrive as the same client as one opened from Details — down to the case of the wallet id.
@Suite("Support chat input", .serialized)
@MainActor
struct SupportChatInputFactoryTests {
    @Test("The chat is opened as the selected wallet, written the way Usedesk stores it")
    func identifiesTheSelectedWallet() async {
        await InjectedEnvironment().run {
            let input = SupportChatInputFactory().makeInput(source: .deeplink)

            #expect(input.userIdentifier == InjectedEnvironment.selectedWalletId.lowercased())
        }
    }

    @Test("A chat opened by a link says so to analytics")
    func deeplinkIsTheSource() async {
        await InjectedEnvironment().run {
            let input = SupportChatInputFactory().makeInput(source: .deeplink)

            #expect(input.source.analyticsParameterValue == .deeplink)
        }
    }
}
