//
//  MCPIntentIssueState.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import enum TangemLocalization.Localization

struct MCPIntentIssueState: Equatable {
    let issue: MCPIntentIssue
    var primaryButton: Self.Button

    init(issue: MCPIntentIssue) {
        self.issue = issue
        primaryButton = issue.isRecoverable ? Button.retry : Button.gotIt
    }
}

extension MCPIntentIssueState {
    struct Button: Equatable {
        let title: String
        var isLoading: Bool

        static let gotIt = Button(title: Localization.commonGotIt, isLoading: false)
        static let retry = Button(title: Localization.commonRetry, isLoading: false)
    }
}
