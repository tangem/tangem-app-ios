//
//  TransactionHistoryJointAccountDataEnriching.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TransactionHistoryJointAccountDataEnriching: Sendable {
    typealias Factory = () async -> TransactionHistoryJointAccountDataEnriching?

    func enrich(with operations: [JointAccountOperation], cryptoAccountId: String) async
    func removeOperations(withIds operationIds: [String]) async
}
