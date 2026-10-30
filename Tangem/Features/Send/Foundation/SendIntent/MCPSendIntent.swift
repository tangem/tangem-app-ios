//
//  MCPSendIntent.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MCPSendIntent: Equatable, Sendable {
    let networkId: String
    let tokenId: String
    let fromAddress: String
    let toAddress: String
    let amount: Decimal
    let memo: String?
    let isCompleted: Bool
    let agentId: String?
}
