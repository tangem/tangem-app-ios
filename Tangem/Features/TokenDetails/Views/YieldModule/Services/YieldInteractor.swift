//
//  YieldInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

actor YieldManagerInteractor {
    private var enterFee: YieldTransactionFee?
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

    func clearFees() {
        enterFee = nil
        exitFee = nil
    }

    func getEnterFee() async throws -> YieldTransactionFee {
        if let existing = enterFeeTask {
            let fee = try await existing.value
            enterFee = fee
            return fee
        }

        let new = Task {
            try await manager.enterFee()
        }
        enterFeeTask = new

        do {
            let fee = try await new.value
            enterFee = fee
            return fee
        } catch {
            enterFeeTask = nil
            throw error
        }
    }

    func getExitFee() async throws -> YieldTransactionFee {
        if let existing = exitFeeTask {
            let fee = try await existing.value
            enterFee = fee
            return fee
        }

        let new = Task {
            try await manager.exitFee()
        }

        exitFeeTask = new

        do {
            let fee = try await new.value
            enterFee = fee
            return fee
        } catch {
            exitFeeTask = nil
            throw error
        }
    }

    func enter() {
        Task {
            guard let fee = enterFee else {
                return
            }

            let _ = try await manager.enter(
                fee: fee,
                transactionDispatcher: transactionDispatcher
            )
        }
    }

    // MARK: - Helpers

    private func loadFee(
        taskRef: inout Task<YieldTransactionFee, Error>?,
        loader: @escaping () async throws -> YieldTransactionFee
    ) async throws -> YieldTransactionFee {
        if let existing = taskRef {
            return try await existing.value
        }

        let newTask = Task {
            try await loader()
        }

        taskRef = newTask

        do {
            return try await newTask.value
        } catch {
            taskRef = nil
            throw error
        }
    }
}
