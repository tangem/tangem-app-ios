//
//  JointOperationHistoryInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

struct JointOperationHistoryInfo: Hashable {
    let item: JointOperationHistoryItem
    let innerCallType: SafeInnerCallType

    var groupingId: String {
        item.operation.id
    }
}
