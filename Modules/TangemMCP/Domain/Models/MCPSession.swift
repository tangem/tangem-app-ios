//
//  MCPSession.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Date
public import struct TangemFoundation.UserWalletId

public struct MCPSession: Identifiable, Equatable, Sendable {
    public let id: String
    public let userWalletID: UserWalletId
    public let agent: MCPAgent
    public let createdAt: Date
}
