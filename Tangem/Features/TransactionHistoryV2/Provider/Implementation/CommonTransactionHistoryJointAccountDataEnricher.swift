//
//  CommonTransactionHistoryJointAccountDataEnricher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

struct CommonTransactionHistoryJointAccountDataEnricher {
    private let jointAccounts: [StoredJointAccount]
    private let writer: JointOperationsHistoryWriter

    init(jointAccounts: [StoredJointAccount], writer: JointOperationsHistoryWriter) {
        self.jointAccounts = jointAccounts
        self.writer = writer
    }

    private func safeAddress(ofAccountWith cryptoAccountId: String) -> String? {
        guard case .active(let safeAddress) = jointAccounts.first(by: cryptoAccountId)?.status else {
            return nil
        }

        return safeAddress.lowercased()
    }
}

// MARK: - TransactionHistoryJointAccountDataEnriching protocol conformance

extension CommonTransactionHistoryJointAccountDataEnricher: TransactionHistoryJointAccountDataEnriching {
    func enrich(with operations: [JointAccountOperation], cryptoAccountId: String) async {
        guard let safeAddress = safeAddress(ofAccountWith: cryptoAccountId) else {
            TransactionHistoryLogger.debug("Skipping \(operations.count) joint operation(s): the account has no active Safe")
            return
        }

        let items = operations.compactMap { operation -> JointOperationHistoryItem? in
            guard let createdAt = operation.createdAt,
                  let threshold = operation.threshold else {
                return nil
            }

            return JointOperationHistoryItem(
                operation: operation,
                cryptoAccountId: cryptoAccountId,
                safeAddress: safeAddress,
                createdAt: createdAt,
                threshold: threshold
            )
        }

        guard items.isNotEmpty else {
            return
        }

        do {
            try await writer.save(local: items)
        } catch {
            TransactionHistoryLogger.error("Failed to save joint operations to the history", error: error)
        }
    }

    func removeOperations(withIds operationIds: [String]) async {
        do {
            try await writer.delete(operationIds: operationIds)
        } catch {
            TransactionHistoryLogger.error("Failed to delete joint operations from the history", error: error)
        }
    }
}
