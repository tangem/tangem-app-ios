//
//  TransactionRecord+JointOperationInfo.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

extension TransactionRecord {
    var jointOperationInfo: JointOperationHistoryInfo? {
        guard case .jointOperation(let jointOperationInfo) = historyExtraInfo else {
            return nil
        }

        return jointOperationInfo
    }
}

extension TransactionRecord {
    func withJointOperationInfo(_ info: JointOperationHistoryInfo) -> TransactionRecord {
        withHistoryExtraInfo(.jointOperation(info))
    }
}
