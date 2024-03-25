//
//  PolkaDotAccountHealthChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import BackgroundTasks

final class PolkaDotAccountHealthChecker {
    private let provider = TangemProvider<SubscanAPITarget>() // [REDACTED_TODO_COMMENT]
    private let encoder: JSONEncoder // [REDACTED_TODO_COMMENT]
    private let decoder: JSONDecoder // [REDACTED_TODO_COMMENT]

    private var currentlyAnalyzingAccounts: Set<String> = []

    // [REDACTED_TODO_COMMENT]
    @AppStorageCompat(StorageKeys.fullyAnalyzedAccounts)
    private var fullyAnalyzedAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedForResetAccounts)
    private var analyzedForResetAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedForImmortalTransactionsAccounts)
    private var analyzedForImmortalTransactionsAccounts: [String] = []

    @AppStorageCompat(StorageKeys.lastAnalyzedTransactionIds)
    private var lastAnalyzedTransactionIds: [String: Int] = [:]

    private let isTestnet: Bool

    private var backgroundTaskIdentifier: String {
        guard let bundleIdentifier: String = InfoDictionaryUtils.bundleIdentifier.value() else {
            preconditionFailure("Unable to get app bundle identifier")
        }
        return bundleIdentifier + "." + Constants.backgroundTaskName
    }

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet

        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        setup() // [REDACTED_TODO_COMMENT]
    }

    func analyzeAccountIfNeeded(_ account: String) {
        guard !fullyAnalyzedAccounts.contains(account) else {
            return
        }

        currentlyAnalyzingAccounts.insert(account)

        runTask(in: self) { try await $0.scheduleForegroundHealthCheck(for: account) }
    }

    // MARK: - Setup

    private func setup() {
        runTask(in: self) { await $0.setupObservers() }
        registerBackgroundTask()
        cancelBackgroundHealthCheck() // Cancels all tasks from previous runs
    }

    private func setupObservers() async {
        for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
            handleApplicationStatusChange(isBackground: true)
        }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
            handleApplicationStatusChange(isBackground: false)
        }
    }

    private func registerBackgroundTask() {
        let result = BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { [weak self] task in
            if let task = task as? BGProcessingTask {
                self?.handleBackgroundProcessingTask(task)
            } else {
                preconditionFailure("Unsupported type of background task '\(type(of: task))' received") // [REDACTED_TODO_COMMENT]
            }
        }
        print(#function, result) // [REDACTED_TODO_COMMENT]
    }

    // MARK: - Foreground health check

    private func scheduleForegroundHealthCheck(for account: String) async throws {
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask {
                await self.checkAccountForReset(account)
            }
            taskGroup.addTask {
                await self.checkIfAccountContainsImmortalTransactions(account)
            }
        }
    }

    // MARK: - Background health check

    private func scheduleBackgroundHealthCheck() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.backgroundTaskDelay) // Allows already running foreground checks to finish
        request.requiresNetworkConnectivity = true

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print(error) // [REDACTED_TODO_COMMENT]
        }
    }

    private func cancelBackgroundHealthCheck() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: backgroundTaskIdentifier)
    }

    private func handleBackgroundProcessingTask(_ task: BGProcessingTask) {}

    @MainActor
    private func handleApplicationStatusChange(isBackground: Bool) {
        if isBackground {
            scheduleBackgroundHealthCheck()
        } else {
            // [REDACTED_TODO_COMMENT]
            cancelBackgroundHealthCheck()
        }
    }

    // MARK: - Shared logic

    private func checkAccountForReset(_ account: String) async {
        guard !analyzedForResetAccounts.contains(account) else {
            return
        }

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        do {
            let accountInfo = try await provider
                .asyncRequest(
                    for: .init(
                        isTestnet: isTestnet,
                        encoder: encoder,
                        target: .getAccountInfo(address: account)
                    )
                )
                .filterSuccessfulStatusAndRedirectCodes()
                .map(SubscanAPIResult.AccountInfo.self, using: decoder)
                .data
                .account

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard !analyzedForResetAccounts.contains(account) else {
                return
            }

            // `accountInfo.nonce` can be equal to or greater than the count of extrinsics,
            // but can't it be less (unless the account has been reset)
            let metric: AccountHealthMetric = .hasBeenReset(value: accountInfo.nonce < accountInfo.countExtrinsic)
            sendAccountHealthMetric(metric)
            analyzedForResetAccounts.append(account)
        } catch {
            print(error) // [REDACTED_TODO_COMMENT]
        }
    }

    private func checkIfAccountContainsImmortalTransactions(_ account: String) async {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        do {
            var foundImmortalTransaction = false

            transactionsListLoop: while true {
                let afterId = lastAnalyzedTransactionIds[account, default: Constants.initialTransactionId]
                let transactions = try await provider
                    .asyncRequest(
                        for: .init(
                            isTestnet: isTestnet,
                            encoder: encoder,
                            target: .getExtrinsicsList(
                                address: account,
                                afterId: afterId,
                                page: Constants.startPage,
                                limit: Constants.pageSize
                            )
                        )
                    )
                    .filterSuccessfulStatusAndRedirectCodes()
                    .map(SubscanAPIResult.ExtrinsicsList.self, using: decoder)
                    .data
                    .extrinsics

                // Checking if we've reached the end of the transactions list
                guard let transactions = transactions?.nilIfEmpty else {
                    break transactionsListLoop
                }

                for transaction in transactions {
                    let isTransactionImmortal = try await isTransactionImmortal(transaction)
                    lastAnalyzedTransactionIds[account] = transaction.id
                    // Early exit if we've found at least one immortal transaction
                    if isTransactionImmortal {
                        foundImmortalTransaction = true
                        break transactionsListLoop
                    }
                }
            }

            // Double checking is a must since theoretically there can be multiple ongoing checks
            guard !analyzedForImmortalTransactionsAccounts.contains(account) else {
                return
            }

            let metric: AccountHealthMetric = .hasImmortalTransaction(value: foundImmortalTransaction)
            sendAccountHealthMetric(metric)
            analyzedForImmortalTransactionsAccounts.append(account)
        } catch {
            print(error) // [REDACTED_TODO_COMMENT]
        }
    }

    private func isTransactionImmortal(_ transaction: SubscanAPIResult.ExtrinsicsList.Extrinsic) async throws -> Bool {
        // Adding small delays between consecutive fetches of transaction details to avoid hitting the API rate limit
        try await _Concurrency.Task.sleep(seconds: Constants.transactionInfoCheckDelay) // [REDACTED_TODO_COMMENT]

        let lifetime = try await provider
            .asyncRequest(
                for: .init(
                    isTestnet: isTestnet,
                    encoder: encoder,
                    target: .getExtrinsicInfo(hash: transaction.extrinsicHash)
                )
            )
            .filterSuccessfulStatusAndRedirectCodes()
            .map(SubscanAPIResult.ExtrinsicInfo.self, using: decoder)
            .data
            .lifetime

        return lifetime == nil
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

private extension PolkaDotAccountHealthChecker {
    enum AccountHealthMetric {
        case hasBeenReset(value: Bool)
        case hasImmortalTransaction(value: Bool)
    }
}

// MARK: - Constants

private extension PolkaDotAccountHealthChecker {
    enum StorageKeys: String, RawRepresentable {
        case fullyAnalyzedAccounts = "polka_dot_account_health_checker_fully_analyzed_accounts"
        case analyzedForResetAccounts = "polka_dot_account_health_checker_analyzed_for_reset_accounts"
        case analyzedForImmortalTransactionsAccounts = "polka_dot_account_health_checker_analyzed_for_immortal_transactions_accounts"
        case lastAnalyzedTransactionIds = "polka_dot_account_health_checker_last_analyzed_transaction_ids"
    }
}

private extension PolkaDotAccountHealthChecker {
    enum Constants {
        /// - Warning: Must match the value specified in the `Info.plist`.
        static let backgroundTaskName = "PolkaDotAccountHealthCheckTask"
        /// 10 minutes.
        static let backgroundTaskDelay = 60.0 * 10.0
        static let initialTransactionId = 0
        static let startPage = 0
        static let transactionInfoCheckDelay = 1.0
        static let pageSize = 100
    }
}
