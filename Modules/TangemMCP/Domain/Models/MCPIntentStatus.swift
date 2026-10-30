//
//  MCPIntentStatus.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum MCPIntentStatus: Equatable, Sendable {
    case sendFinished(amount: String?)
    case unreachable(canRetry: Bool)
}
