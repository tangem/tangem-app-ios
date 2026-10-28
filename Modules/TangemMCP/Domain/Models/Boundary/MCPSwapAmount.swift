//
//  MCPSwapAmount.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct MCPSwapAmount: Equatable, Sendable {
    let token: MCPToken
    let formattedValue: String

    public init(token: MCPToken, formattedValue: String) {
        self.token = token
        self.formattedValue = formattedValue
    }
}
