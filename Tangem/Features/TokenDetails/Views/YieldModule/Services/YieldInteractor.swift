//
//  YieldInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

actor YieldManagerInteractor {
    private(set) var enterFee: YieldTransactionFee?
    private var exitFee: YieldTransactionFee?

    private var enterFeeTask: Task<YieldTransactionFee, Error>?
    private var exitFeeTask: Task<YieldTransactionFee, Error>?

    // MARK: - Dependencies

    private let transactionDispatcher: YieldModuleTransactionDispatcher
    private let manager: YieldModuleManager

    // MARK: - Init

    init(
        transactionDispatcher: YieldModuleTransactionDispatcher,
        manager: YieldModuleManager
    ) {
        self.transactionDispatcher = transactionDispatcher
        self.manager = manager
    }

    // MARK: - Public Implementation

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

    func enter() {
        runTask(in: self) { actor in
            guard let fee = await actor.enterFee else {
                return
            }

            _ = try await actor.manager.enter(fee: fee, transactionDispatcher: actor.transactionDispatcher)
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
