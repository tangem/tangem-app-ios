//
//  JointOperationHistoryInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct JointOperationHistoryInfo: Hashable {
    let item: JointOperationHistoryItem

    var groupingId: String {
        item.operation.id
    }
}
