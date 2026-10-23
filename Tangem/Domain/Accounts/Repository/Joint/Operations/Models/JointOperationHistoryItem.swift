//
//  JointOperationHistoryItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointOperationHistoryItem: Hashable {
    let operation: JointAccountOperation
    let cryptoAccountId: String
    let safeAddress: String
    let createdAt: Date
    let finishedAt: Date?
    let threshold: Int
    let cancelReason: JointOperationCancelReason?
}
