//
//  YieldManagerInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

actor YieldManagerInteractor {
    private(set) var enterFee: YieldTransactionFee?
    private var exitFee: YieldTransactionFee?

    private var enterFeeTask: Task<YieldTransactionFee, Error>?
    private var exitFeeTask: Task<YieldTransactionFee, Error>?

    // MARK: - Dependencies

    private let transactionDispatcher: YieldModuleTransactionDispatcher
    private let manager: YieldModuleManager
    private let yieldModuleNotificationInteractor: YieldModuleNoticeInteractor

    // MARK: - Init

    init(
        transactionDispatcher: YieldModuleTransactionDispatcher,
        manager: YieldModuleManager,
        yieldModuleNotificationInteractor: YieldModuleNoticeInteractor
    ) {
        self.transactionDispatcher = transactionDispatcher
        self.manager = manager
        self.yieldModuleNotificationInteractor = yieldModuleNotificationInteractor
    }

    // MARK: - Public Implementation

    func getApy() async throws -> Decimal {
        if let apy = manager.state?.marketInfo?.apy {
            return apy
        } else {
            let info = try await manager.fetchYieldTokenInfo()
            return info.apy
        }
    }

    func clearAll() {
        enterFee = nil
        exitFee = nil
        enterFeeTask = nil
        exitFeeTask = nil
    }

    func getEnterFee() async throws -> YieldTransactionFee {
        try await loadFee(
            getTask: { enterFeeTask },
            setTask: { enterFeeTask = $0 },
            setCache: { enterFee = $0 },
            loader: {
                try await self.manager.enterFee()
            }
        )
    }

    func getExitFee() async throws -> YieldTransactionFee {
        try await loadFee(
            getTask: { exitFeeTask },
            setTask: { exitFeeTask = $0 },
            setCache: { exitFee = $0 },
            loader: {
                try await self.manager.exitFee()
            }
        )
    }

    /// Initiates the "enter" operation for the given token.
    /// This is a fire-and-forget task: it triggers the manager call
    /// and updates the withdrawal alert state on completion,
    /// without propagating any result or error back to the caller.
    func enter(with token: TokenItem) {
        runTask(in: self) { actor in
            guard let fee = await actor.enterFee else {
                return
            }

            _ = try await actor.manager.enter(fee: fee, transactionDispatcher: actor.transactionDispatcher)
            await actor.yieldModuleNotificationInteractor.markWithdrawalAlertShouldShow(for: token)
        }
    }

    /// Initiates the "enter" operation for the given token.
    /// This is also a fire-and-forget task
    func exit(with token: TokenItem) {
        runTask(in: self) { actor in
            guard let fee = await actor.exitFee else {
                return
            }

            _ = try? await actor.manager.exit(fee: fee, transactionDispatcher: actor.transactionDispatcher)
        }
    }

    // MARK: - Heplers

    private func loadFee(
        getTask: () -> Task<YieldTransactionFee, Error>?,
        setTask: (Task<YieldTransactionFee, Error>?) -> Void,
        setCache: (YieldTransactionFee) -> Void,
        loader: @Sendable @escaping () async throws -> YieldTransactionFee
    ) async throws -> YieldTransactionFee {
        if let existing = getTask() {
            let fee = try await existing.value
            setCache(fee)
            return fee
        }

        let new = Task { try await loader() }
        setTask(new)

        do {
            let fee = try await new.value
            setCache(fee)
            return fee
        } catch {
            setTask(nil)
            throw error
        }
    }
}
