//
//  JointOperationsHistoryPage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct JointOperationsHistoryPage: Hashable {
    let items: [JointOperationHistoryItem]
    let nextCursor: String?
    let startDeltaCursor: String?
    let hasMore: Bool
}
