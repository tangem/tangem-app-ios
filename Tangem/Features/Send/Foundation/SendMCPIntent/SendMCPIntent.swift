//
//  SendMCPIntent.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A send an AI agent proposed through MCP, fetched by it's intentID from a deeplink `tangem://intent?...`.
struct SendMCPIntent: Identifiable, Equatable, Sendable {
    let id: String
    let networkID: String
    let tokenID: String
    let fromAddress: String
    let toAddress: String
    let amount: Decimal
    let memo: String?
    let isCompleted: Bool
    let agentID: String
}
