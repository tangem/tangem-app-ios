//
//  SupportChatSourceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Support chat source")
struct SupportChatSourceTests {
    @Test("Swap and Polymarket chats are routed by topic, the general ones are not", arguments: [
        (SupportChatSource.swap, SupportChatTopic?.some(.swap)),
        (.polymarket, .polymarket),
        (.settings, nil),
        (.deeplink, nil),
    ])
    func topicFollowsTheSource(source: SupportChatSource, expectedTopic: SupportChatTopic?) {
        #expect(source.topic == expectedTopic)
    }

    @Test("Each source reports its own value to analytics", arguments: [
        (SupportChatSource.settings, Analytics.ParameterValue.settings),
        (.swap, .swap),
        (.deeplink, .deeplink),
        (.polymarket, .predictions),
    ])
    func analyticsValueFollowsTheSource(source: SupportChatSource, expectedValue: Analytics.ParameterValue) {
        #expect(source.analyticsParameterValue == expectedValue)
    }
}
