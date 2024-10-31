//
//  ExitAction.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct ExitAction: Hashable {
    public let id: String
    public let status: ActionStatus
    public let amount: Decimal
    public let currentStepIndex: Int
    public let transactions: [ActionTransaction]
}
