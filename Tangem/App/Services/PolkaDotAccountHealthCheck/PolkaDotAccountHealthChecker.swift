//
//  PolkaDotAccountHealthChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Moya

final class PolkaDotAccountHealthChecker {
    private let provider = TangemProvider<SubscanAPITarget>() // [REDACTED_TODO_COMMENT]
    private let decoder: JSONDecoder // [REDACTED_TODO_COMMENT]

    // [REDACTED_TODO_COMMENT]
    @AppStorageCompat(StorageKeys.analyzedAccounts)
    private var analyzedAccounts: [String] = []

    @AppStorageCompat(StorageKeys.analyzedPages)
    private var analyzedNonceCountMismatches: [String] = []

    @AppStorageCompat(StorageKeys.analyzedPages)
    private var analyzedPages: [String: [Int]] = [:]

    private let isTestnet: Bool

    init(isTestnet: Bool) {
        self.isTestnet = isTestnet
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        setup() // [REDACTED_TODO_COMMENT]
    }

    func analyzeAccountIfNeeded(_ account: String) {
        if analyzedAccounts.contains(account) {
            return
        }

        runTask(in: self) { try await $0.scheduleNormalHealthCheck(for: account) }
    }

    private func setup() {
        runTask(in: self) { await $0.setupObservers() }
    }

    private func setupObservers() async {
        for await _ in NotificationCenter.default.notifications(named: UIApplication.backgroundRefreshStatusDidChangeNotification) {
            handleBackgroundRefreshStatusChange()
        }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
            handleApplicationStatusChange(isBackground: true)
        }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification) {
            handleApplicationStatusChange(isBackground: false)
        }
    }

    private func scheduleNormalHealthCheck(for account: String) async throws {
        await checkNonceCountMismatch(for: account)
        await checkImmortalTransactions(for: account)
    }

    private func checkNonceCountMismatch(for account: String) async {
        // [REDACTED_TODO_COMMENT]
        if analyzedNonceCountMismatches.contains(account) {
            return
        }

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        do {
            let accountInfo = try await provider
                .asyncRequest(for: .init(isTestnet: isTestnet, target: .getAccountInfo(address: account)))
                .filterSuccessfulStatusAndRedirectCodes()
                .map(SubscanAPIResult.AccountInfo.self, using: decoder)
                .data
                .account

            if analyzedNonceCountMismatches.contains(account) {
                return
            }

            // `accountInfo.nonce` can be equal to or greater than the count of extrinsics,
            // but can't it be less (unless the account has been reset)
            let metric: AccountHealthMetric = .hasNonceCountMismatch(value: accountInfo.nonce < accountInfo.countExtrinsic)
            sendAccountHealthMetric(metric)
            analyzedNonceCountMismatches.append(account)
        } catch {
            // [REDACTED_TODO_COMMENT]
        }
    }

    private func checkImmortalTransactions(for account: String) async {
        // [REDACTED_TODO_COMMENT]
    }

    private func scheduleBackgroundHealthCheck(for account: String) {}

    @MainActor
    private func handleBackgroundRefreshStatusChange() {
        // [REDACTED_TODO_COMMENT]
    }

    @MainActor
    private func handleApplicationStatusChange(isBackground: Bool) {
        // [REDACTED_TODO_COMMENT]
    }

    @MainActor
    private func sendAccountHealthMetric(_ metric: AccountHealthMetric) {}
}

// MARK: - Auxiliary types

private extension PolkaDotAccountHealthChecker {
    enum AccountHealthMetric {
        case hasNonceCountMismatch(value: Bool)
        case hasImmortalTransaction(value: Bool)
    }
}

// MARK: - Constants

private extension PolkaDotAccountHealthChecker {
    enum StorageKeys: String, RawRepresentable {
        case analyzedAccounts = "polka_dot_account_health_checker_analyzed_accounts"
        case analyzedNonceMismatches = "polka_dot_account_health_checker_analyzed_nonce_mismatches"
        case analyzedPages = "polka_dot_account_health_checker_analyzed_pages"
    }
}
