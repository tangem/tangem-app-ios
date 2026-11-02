//
//  MCPIntentIssue.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct MCPIntentIssue: Equatable, Sendable {
    public let severity: Self.Severity
    public let title: String
    public let subtitle: String?
    public let isRecoverable: Bool

    public init(severity: Self.Severity, title: String, subtitle: String?, isRecoverable: Bool) {
        self.severity = severity
        self.title = title
        self.subtitle = subtitle
        self.isRecoverable = isRecoverable
    }
}

public extension MCPIntentIssue {
    enum Severity: Equatable, Sendable {
        case notice
        case error
    }
}
