//
//  MCPIntentStatusStateTests.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemMCP

struct MCPIntentStatusStateTests {
    @Test(arguments: [
        StatusTestCase(
            status: .sendFinished(amount: "0.0001 ETH"),
            tone: .info,
            title: "This intent already was finished",
            subtitle: "Send 0.0001 ETH",
            buttonTitle: "To transactions"
        ),
        StatusTestCase(
            status: .sendFinished(amount: nil),
            tone: .info,
            title: "This intent already was finished",
            subtitle: nil,
            buttonTitle: "Got it"
        ),
        StatusTestCase(
            status: .unreachable(canRetry: true),
            tone: .warning,
            title: "Can’t reach intent",
            subtitle: nil,
            buttonTitle: "Try again"
        ),
        StatusTestCase(
            status: .unreachable(canRetry: false),
            tone: .warning,
            title: "Can’t reach intent",
            subtitle: nil,
            buttonTitle: "Got it"
        ),
    ])
    private func describesStatus(testCase: StatusTestCase) {
        let state = MCPIntentStatusState(status: testCase.status)

        #expect(state.tone == testCase.tone)
        #expect(state.title == testCase.title)
        #expect(state.subtitle == testCase.subtitle)
        #expect(state.buttonTitle == testCase.buttonTitle)
    }
}

// MARK: - Test cases

extension MCPIntentStatusStateTests {
    private struct StatusTestCase {
        let status: MCPIntentStatus
        let tone: MCPIntentStatusState.Tone
        let title: String
        let subtitle: String?
        let buttonTitle: String
    }
}
