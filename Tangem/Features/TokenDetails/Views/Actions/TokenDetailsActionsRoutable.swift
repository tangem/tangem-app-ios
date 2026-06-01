//
//  TokenDetailsActionsRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@MainActor
protocol TokenDetailsActionsRoutable: AnyObject {
    func performTokenAction(_ type: TokenActionType)
    func copyDefaultAddress()
}
