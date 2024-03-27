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

/// - Warning: Read-write access to all `@AppStorageCompat` properties must be synchronized (e.g. by using `runOnMain(_:)` helper).
final class PolkadotAccountHealthChecker {
    private let networkService: PolkadotAccountHealthNetworkService

    @AppStorageCompat(StorageKeys.analyzedForResetAccounts)
    private var analyzedForResetAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedForImmortalTransactionsAccounts)
    private var analyzedForImmortalTransactionsAccounts: [String] = []

    @AppStorageCompat(StorageKeys.lastAnalyzedTransactionIds)
    private var lastAnalyzedTransactionIds: [String: Int] = [:]

    private var currentlyAnalyzedAccounts: Set<String> = []

    private var healthCheckTasks: [String: Task<Void, Never>] = [:]

    private var willEnterForegroundNotificationObserver: Task<Void, Never>?

    private var transactionInfoCheckDelay: TimeInterval {
        return Constants.transactionInfoCheckDelayBaseValue
            + .random(in: Constants.transactionInfoCheckDelayJitterMinValue ... Constants.transactionInfoCheckDelayJitterMaxValue)
    }

    init(networkService: PolkadotAccountHealthNetworkService) {
        self.networkService = networkService
        subscribeToNotifications()
    }

    private func subscribeToNotifications() {
        willEnterForegroundNotificationObserver = Task.detached { [weak self] in
            for await _ in await NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
                await self?.handleWillEnterForegroundNotification()
            }
        }
    }

    @MainActor
    private func handleWillEnterForegroundNotification() {
        for account in currentlyAnalyzedAccounts where healthCheckTasks[account] == nil {
            AppLog.shared.debugDetailed("Found an incomplete health check for account '\(account)', restarting health check")
            performAccountCheck(account)
        }
    }

    private func performAccountCheck(_ account: String) {
        currentlyAnalyzedAccounts.insert(account)
        healthCheckTasks[account] = runTask(in: self) { await $0.checkAccount(account) }
    }

    private func checkAccount(_ account: String) async {
        let backgroundTaskName = "com.tangem.PolkadotAccountHealthChecker_\(account)_\(UUID().uuidString)"
        let backgroundTask = BackgroundTaskWrapper(taskName: backgroundTaskName) { [weak self] in
            self?.healthCheckTasks[account]?.cancel()
            self?.healthCheckTasks[account] = nil
            AppLog.shared.debugDetailed("Background task has expired while checking account '\(account)'")
        }

        defer {
            backgroundTask.finish()
            runOnMain { healthCheckTasks[account] = nil }
            AppLog.shared.debugDetailed("Cleaning up after checking account '\(account)'")
        }

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

        guard !Task.isCancelled else {
            return
        }

        runOnMain { currentlyAnalyzedAccounts.remove(account) }
        AppLog.shared.debugDetailed("Finished checking account '\(account)'")
    }

    private func checkAccountForReset(_ account: String) async {
        guard runOnMain({ !analyzedForResetAccounts.contains(account) }) else {
            return
        }

        do {
            let accountInfo = try await networkService.getAccountHealthInfo(account: account)
            try Task.checkCancellation()

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard runOnMain({ !analyzedForResetAccounts.contains(account) }) else {
                return
            }

            // `accountInfo.nonceCount` can be equal to or greater than the count of extrinsics,
            // but can't it be less (unless the account has been reset)
            sendAccountHealthMetric(.hasBeenReset(value: accountInfo.nonceCount < accountInfo.extrinsicCount))
            runOnMain { analyzedForResetAccounts.append(account) }
            AppLog.shared.debugDetailed("Finished checking account '\(account)' for reset")
        } catch {
            AppLog.shared.debugDetailed("Failed to check account '\(account)' for reset due to error: '\(error)'")
            AppLog.shared.error(error)
        }
    }

    private func checkIfAccountContainsImmortalTransactions(_ account: String) async {
        guard runOnMain({ !analyzedForImmortalTransactionsAccounts.contains(account) }) else {
            return
        }

        do {
            var foundImmortalTransaction = false

            transactionsListLoop: while true {
                let afterId = runOnMain { lastAnalyzedTransactionIds[account, default: Constants.initialTransactionId] }
                let transactions = try await networkService.getTransactionsList(account: account, afterId: afterId)
                try Task.checkCancellation()

                // Checking if we've reached the end of the transactions list
                guard !transactions.isEmpty else {
                    break transactionsListLoop
                }

                for transaction in transactions {
                    // Adding small delays between consecutive fetches of transaction details to avoid hitting the API rate limit
                    try await Task.sleep(seconds: transactionInfoCheckDelay)

                    let isTransactionImmortal = try await isTransactionImmortal(transaction)
                    try Task.checkCancellation()

                    runOnMain { lastAnalyzedTransactionIds[account] = transaction.id }

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
            guard runOnMain({ !analyzedForImmortalTransactionsAccounts.contains(account) }) else {
                return
            }

            sendAccountHealthMetric(.hasImmortalTransaction(value: foundImmortalTransaction))
            runOnMain { analyzedForImmortalTransactionsAccounts.append(account) }
            AppLog.shared.debugDetailed("Finished checking account '\(account)' for immortal transactions")
        } catch {
            AppLog.shared.debugDetailed("Failed to check account '\(account)' for immortal transactions due to error: '\(error)'")
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

// MARK: - AccountHealthChecker protocol conformance

extension PolkadotAccountHealthChecker: AccountHealthChecker {
    func performAccountCheckIfNeeded(_ account: String) {
        assert(Thread.isMainThread, "Non-synchronized access is prohibited")

        guard
            !analyzedForResetAccounts.contains(account) || !analyzedForImmortalTransactionsAccounts.contains(account),
            !currentlyAnalyzedAccounts.contains(account)
        else {
            return
        }

        AppLog.shared.debugDetailed("Starting checking account '\(account)'")
        performAccountCheck(account)
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
        static let transactionInfoCheckDelayBaseValue = 1.5
        static var transactionInfoCheckDelayJitterMinValue: TimeInterval { -transactionInfoCheckDelayJitterMaxValue }
        static var transactionInfoCheckDelayJitterMaxValue: TimeInterval { 0.5 }
    }
}
