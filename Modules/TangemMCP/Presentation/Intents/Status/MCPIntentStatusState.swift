//
//  MCPIntentStatusState.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

// [REDACTED_TODO_COMMENT]
public struct MCPIntentStatusState: Equatable {
    let tone: Tone
    let title: String
    let subtitle: String?
    let buttonTitle: String

    init(status: MCPIntentStatus) {
        switch status {
        case .sendFinished(let amount):
            tone = .info
            title = "This intent already was finished"
            subtitle = amount.map { "Send \($0)" }
            buttonTitle = amount == nil ? "Got it" : "To transactions"

        case .unreachable(let canRetry):
            tone = .warning
            title = "Can’t reach intent"
            subtitle = nil
            buttonTitle = canRetry ? "Try again" : "Got it"
        }
    }
}

extension MCPIntentStatusState {
    enum Tone: Equatable {
        case warning
        case info
    }
}
