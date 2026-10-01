//
//  SupportChatHTMLBuilderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Support chat widget HTML")
struct SupportChatHTMLBuilderTests {
    @Test("A Polymarket chat fills the Usedesk topic field with polymarket")
    func polymarketTopicFillsTheUsedeskField() {
        let html = makeHTML(topic: .polymarket)

        #expect(html.contains(#"additional_fields: [{ id: 245, value: "polymarket" }]"#))
    }

    @Test("A swap chat fills the Usedesk topic field with swap")
    func swapTopicFillsTheUsedeskField() {
        let html = makeHTML(topic: .swap)

        #expect(html.contains(#"additional_fields: [{ id: 245, value: "swap" }]"#))
    }

    @Test("A chat without a topic leaves the Usedesk topic field out")
    func noTopicLeavesTheUsedeskFieldOut() {
        let html = makeHTML(topic: nil)

        #expect(!html.contains("additional_fields"))
    }

    private func makeHTML(topic: SupportChatTopic?) -> String {
        SupportChatHTMLBuilder.makeWidgetHTML(userIdentifier: "wallet-id", savedToken: nil, topic: topic, initialMessage: nil)
    }
}
