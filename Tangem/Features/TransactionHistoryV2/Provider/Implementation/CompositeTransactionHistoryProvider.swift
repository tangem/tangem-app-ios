//
//  CompositeTransactionHistoryProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

final class CompositeTransactionHistoryProvider: Sendable {
    private let expressProvider: any TransactionHistoryProviding
    private let jointOperationsSyncService: any JointOperationsHistorySyncing

    init(
        expressProvider: any TransactionHistoryProviding,
        jointOperationsSyncService: any JointOperationsHistorySyncing
    ) {
        self.expressProvider = expressProvider
        self.jointOperationsSyncService = jointOperationsSyncService
    }

    private func combinedState(
        express: TransactionHistorySyncState,
        jointOperations: TransactionHistorySyncState
    ) -> TransactionHistorySyncState {
        switch (express, jointOperations) {
        case (.syncing(let kind), _), (_, .syncing(let kind)):
            return .syncing(kind)
        case (.failed(let failure), .failed):
            return .failed(failure)
        case (.failed(let failure), .idle):
            return .failed(.init(reason: .partialFailure(failedProviders: [Constants.expressProviderName]), syncKind: failure.syncKind))
        case (.idle, .failed(let failure)):
            return .failed(.init(reason: .partialFailure(failedProviders: [Constants.jointOperationsProviderName]), syncKind: failure.syncKind))
        case (.idle(let reason), .idle):
            return .idle(reason)
        }
    }
}

// MARK: - TransactionHistorySyncing protocol conformance

extension CompositeTransactionHistoryProvider: TransactionHistorySyncing {
    var state: TransactionHistorySyncState {
        get async {
            combinedState(express: await expressProvider.state, jointOperations: await jointOperationsSyncService.state)
        }
    }

    var stateUpdates: AsyncStream<TransactionHistorySyncState> {
        expressProvider.stateUpdates
    }

    func syncInitial() async {
        async let expressSync: Void = expressProvider.syncInitial()
        async let jointOperationsSync: Void = jointOperationsSyncService.syncInitial()
        _ = await (expressSync, jointOperationsSync)
    }

    func syncDelta() async {
        async let expressSync: Void = expressProvider.syncDelta()
        async let jointOperationsSync: Void = jointOperationsSyncService.syncDelta()
        _ = await (expressSync, jointOperationsSync)
    }

    func syncUserInitiated(_ kind: UserInitiatedSyncKind) async {
        async let expressSync: Void = expressProvider.syncUserInitiated(kind)
        async let jointOperationsSync: Void = jointOperationsSyncService.syncUserInitiated(kind)
        _ = await (expressSync, jointOperationsSync)
    }
}

// MARK: - TransactionHistoryExpressDataEnriching protocol conformance

extension CompositeTransactionHistoryProvider: TransactionHistoryExpressDataEnriching {
    func enrich(with transaction: SentSwapTransactionData) async {
        await expressProvider.enrich(with: transaction)
    }

    func enrich(with transaction: SentOnrampTransactionData) async {
        await expressProvider.enrich(with: transaction)
    }

    func enrich(with transaction: ExchangeTransaction) async {
        await expressProvider.enrich(with: transaction)
    }

    func enrich(with transaction: OnrampTransaction) async {
        await expressProvider.enrich(with: transaction)
    }
}

// MARK: - Identifiable protocol conformance

extension CompositeTransactionHistoryProvider: Identifiable {
    var id: AnyHashable {
        expressProvider.id.toAnyHashable()
    }
}

// MARK: - TransactionHistoryProviding protocol conformance

extension CompositeTransactionHistoryProvider: TransactionHistoryProviding {
    var mappingQueue: DispatchQueue {
        expressProvider.mappingQueue
    }

    func historyUpdates(
        for walletModelId: WalletModelId,
        walletModelAddressesPublisher: some Publisher<[String], Never>
    ) -> AsyncStream<[TransactionHistoryRecordsReader.Record]> {
        expressProvider.historyUpdates(for: walletModelId, walletModelAddressesPublisher: walletModelAddressesPublisher)
    }
}

// MARK: - Constants

private extension CompositeTransactionHistoryProvider {
    enum Constants {
        static let expressProviderName = "express"
        static let jointOperationsProviderName = "jointOperations"
    }
}
