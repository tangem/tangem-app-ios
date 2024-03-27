//
//  PolkadotAccountHealthChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import BlockchainSdk

// [REDACTED_TODO_COMMENT]
final class PolkadotAccountHealthChecker {
    static let shared = PolkadotAccountHealthChecker()

    @Injected(\.polkadotAccountHealthNetworkService)
    private var networkService: PolkadotAccountHealthNetworkService

    @AppStorageCompat(StorageKeys.fullyAnalyzedAccounts)
    private var fullyAnalyzedAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedForResetAccounts)
    private var analyzedForResetAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedForImmortalTransactionsAccounts)
    private var analyzedForImmortalTransactionsAccounts: [String] = []

    @AppStorageCompat(StorageKeys.lastAnalyzedTransactionIds)
    private var lastAnalyzedTransactionIds: [String: Int] = [:]

    private var healthCheckTasks: [String: Task<Void, Never>] = [:]

    private init() {}

    func performAccountCheckIfNeeded(_ account: String) {
        guard !fullyAnalyzedAccounts.contains(account) else {
            return
        }

        healthCheckTasks[account] = runTask(in: self) { await $0.scheduleForegroundHealthCheck(for: account) }
    }

    private func scheduleForegroundHealthCheck(for account: String) async {
        let backgroundTaskName = "com.tangem.PolkadotAccountHealthChecker_\(account)_\(UUID().uuidString)"
        let backgroundTask = BackgroundTaskWrapper(taskName: backgroundTaskName) { [weak self] in
            self?.healthCheckTasks[account]?.cancel()
            self?.healthCheckTasks[account] = nil
        }

        await withTaskCancellationHandler(
            operation: {
                // This check is required since `operation` closure is called regardless of whether the task is cancelled or not
                guard !Task.isCancelled else {
                    return
                }

                await withTaskGroup(of: Void.self) { taskGroup in
                    taskGroup.addTask {
                        await self.checkAccountForReset(account)
                    }
                    taskGroup.addTask {
                        await self.checkIfAccountContainsImmortalTransactions(account)
                    }
                }

                // `BackgroundTaskWrapper.finish` can be safely called multiple times,
                // therefore no additional check for the task cancellation here
                backgroundTask.finish()
            },
            onCancel: {
                backgroundTask.finish()
            }
        )
    }

    private func checkAccountForReset(_ account: String) async {
        guard !analyzedForResetAccounts.contains(account) else {
            return
        }

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        do {
            let accountInfo = try await networkService.getAccountHealthInfo(account: account)
            try Task.checkCancellation()

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard !analyzedForResetAccounts.contains(account) else {
                return
            }

            // `accountInfo.nonceCount` can be equal to or greater than the count of extrinsics,
            // but can't it be less (unless the account has been reset)
            sendAccountHealthMetric(.hasBeenReset(value: accountInfo.nonceCount < accountInfo.extrinsicCount))
            analyzedForResetAccounts.append(account)
        } catch {
            AppLog.shared.debug("Failed to check Polkadot account for reset due to error: '\(error)'")
            AppLog.shared.error(error)
        }
    }

    private func checkIfAccountContainsImmortalTransactions(_ account: String) async {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        do {
            var foundImmortalTransaction = false

            transactionsListLoop: while true {
                let afterId = lastAnalyzedTransactionIds[account, default: Constants.initialTransactionId]
                let transactions = try await networkService.getTransactionsList(account: account, afterId: afterId)
                try Task.checkCancellation()

                // Checking if we've reached the end of the transactions list
                guard !transactions.isEmpty else {
                    break transactionsListLoop
                }

                for transaction in transactions {
                    // Adding small delays between consecutive fetches of transaction details to avoid hitting the API rate limit
                    try await Task.sleep(seconds: Constants.transactionInfoCheckDelay) // [REDACTED_TODO_COMMENT]

                    let isTransactionImmortal = try await isTransactionImmortal(transaction)
                    try Task.checkCancellation()
                    lastAnalyzedTransactionIds[account] = transaction.id

                    // Early exit if we've found at least one immortal transaction
                    if isTransactionImmortal {
                        foundImmortalTransaction = true
                        break transactionsListLoop
                    }
                }
            }

            // The loop above may take quite a while to finish, therefore we're checking for cancellation here
            try Task.checkCancellation()

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard !analyzedForImmortalTransactionsAccounts.contains(account) else {
                return
            }

            sendAccountHealthMetric(.hasImmortalTransaction(value: foundImmortalTransaction))
            analyzedForImmortalTransactionsAccounts.append(account)
        } catch {
            AppLog.shared.debug("Failed to check Polkadot account for immortal transactions due to error: '\(error)'")
            AppLog.shared.error(error)
        }
    }

    private func isTransactionImmortal(_ transaction: PolkadotTransaction) async throws -> Bool {
        let transactionDetails = try await networkService.getTransactionDetails(hash: transaction.hash)
        try Task.checkCancellation()

        return transactionDetails.birth == nil || transactionDetails.death == nil
    }

    @MainActor
    private func sendAccountHealthMetric(_ metric: AccountHealthMetric) {
        switch metric {
        case .hasBeenReset(let value):
            let value: Analytics.ParameterValue = .affirmativeOrNegative(for: value)
            Analytics.log(event: .healthCheckPolkadotAccountReset, params: [.state: value.rawValue])
        case .hasImmortalTransaction(let value):
            let value: Analytics.ParameterValue = .affirmativeOrNegative(for: value)
            Analytics.log(event: .healthCheckPolkadotImmortalTransactions, params: [.state: value.rawValue])
        }
    }
}

// MARK: - Auxiliary types

private extension PolkadotAccountHealthChecker {
    enum AccountHealthMetric {
        case hasBeenReset(value: Bool)
        case hasImmortalTransaction(value: Bool)
    }
}

// MARK: - Constants

private extension PolkadotAccountHealthChecker {
    enum StorageKeys: String, RawRepresentable {
        case fullyAnalyzedAccounts = "polka_dot_account_health_checker_fully_analyzed_accounts"
        case analyzedForResetAccounts = "polka_dot_account_health_checker_analyzed_for_reset_accounts"
        case analyzedForImmortalTransactionsAccounts = "polka_dot_account_health_checker_analyzed_for_immortal_transactions_accounts"
        case lastAnalyzedTransactionIds = "polka_dot_account_health_checker_last_analyzed_transaction_ids"
    }
}

private extension PolkadotAccountHealthChecker {
    enum Constants {
        static let initialTransactionId = 0
        static let transactionInfoCheckDelay = 1.0
    }
}
