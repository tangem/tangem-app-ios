//
//  TransactionHistoryJointAccountDataEnricherFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TransactionHistoryJointAccountDataEnricherFactory {
    static func make(
        persistentStorage: JointAccountsPersistentStorage,
        isJointAccountsAvailable: Bool
    ) -> TransactionHistoryJointAccountDataEnriching.Factory {
        guard isJointAccountsAvailable else {
            return { nil }
        }

        let writer = CommonJointOperationsHistoryWriter(writer: CommonTransactionHistoryRecordsWriter())

        return {
            CommonTransactionHistoryJointAccountDataEnricher(jointAccounts: persistentStorage.getList(), writer: writer)
        }
    }
}
