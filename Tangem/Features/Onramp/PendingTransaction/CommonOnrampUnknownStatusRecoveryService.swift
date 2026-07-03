//
//  CommonOnrampUnknownStatusRecoveryService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

final class CommonOnrampUnknownStatusRecoveryService {
    @Injected(\.onrampUnknownStatusRepository) private var unknownStatusRepository: OnrampUnknownStatusRepository
    @Injected(\.onrampPendingTransactionsRepository) private var pendingRepository: OnrampPendingTransactionRepository

    private let userWalletId: UserWalletId
    private let tokenItem: TokenItem
    private let expressAPIProvider: ExpressAPIProvider

    private var observationTask: Task<Void, Never>?
    private var tickTask: Task<Void, Never>?
    private var recoveryTask: Task<Void, Never>?

    init(userWalletId: UserWalletId, tokenItem: TokenItem, expressAPIProvider: ExpressAPIProvider) {
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.expressAPIProvider = expressAPIProvider
    }

    deinit {
        cancel()
    }

    private func runRecoveryPass() {
        recoveryTask?.cancel()
        recoveryTask = runTask(in: self) { service in
            let currency = service.tokenItem.expressCurrency
            let toContractAddress = currency.contractAddress
            let toNetwork = currency.network
            let records = service.unknownStatusRepository.pendingRecoveryCandidates(
                userWalletId: service.userWalletId.stringValue,
                toContractAddress: toContractAddress,
                toNetwork: toNetwork
            )
            guard !records.isEmpty else { return }

            let recordsByAddress = Dictionary(grouping: records, by: \.payoutAddress)

            await withTaskGroup(of: Void.self) { group in
                for (payoutAddress, recordsForAddress) in recordsByAddress {
                    group.addTask {
                        await service.recoverGroup(
                            payoutAddress: payoutAddress,
                            records: recordsForAddress,
                            toContractAddress: toContractAddress,
                            toNetwork: toNetwork
                        )
                    }
                }
            }
        }
    }

    private func recoverGroup(
        payoutAddress: String,
        records: [OnrampUnknownStatusRecord],
        toContractAddress: String,
        toNetwork: String
    ) async {
        guard !Task.isCancelled else { return }

        for record in records {
            unknownStatusRepository.noteRecoveryProbe(recordId: record.id)
        }

        let historyRecords: [OnrampTransaction]
        do {
            let page = try await expressAPIProvider.onrampHistory(
                item: ExpressHistoryRequestItem(walletAddress: payoutAddress, cursor: nil, limit: OnrampUnknownStatusRepositoryConstants.historyPageLimit)
            )
            historyRecords = page.records
        } catch {
            OnrampLogger.error("Recovery: history fetch failed for payoutAddress=\(payoutAddress)", error: error)
            return
        }

        for record in records {
            guard !Task.isCancelled else { return }

            let match = OnrampHistoryMatcher.findMatch(
                in: historyRecords,
                since: record.since,
                toContractAddress: toContractAddress,
                toNetwork: toNetwork,
                providerId: record.provider.id
            )

            if let match {
                persistRecovered(historyItem: match, from: record)
                unknownStatusRepository.untrack(recordId: record.id)
            }
        }
    }

    private func persistRecovered(historyItem: OnrampTransaction, from record: OnrampUnknownStatusRecord) {
        let pendingRecord = OnrampPendingTransactionRecord(
            userWalletId: record.userWalletId,
            expressTransactionId: historyItem.txId,
            fromAmount: historyItem.from.amount,
            fromCurrencyCode: historyItem.from.currencyCode,
            destinationTokenTxInfo: .init(
                userWalletId: record.userWalletId,
                tokenItem: tokenItem,
                address: record.payoutAddress,
                amountString: "",
                isCustom: false
            ),
            provider: record.provider,
            paymentMethod: record.paymentMethod,
            date: historyItem.createdAt,
            externalTxId: historyItem.externalTx?.id,
            externalTxURL: historyItem.externalTx?.url?.absoluteString,
            isHidden: false,
            transactionStatus: PendingOnrampTransactionFactory.pendingStatus(from: historyItem.status)
        )
        pendingRepository.addRecordIfNeeded(pendingRecord)
    }
}

extension CommonOnrampUnknownStatusRecoveryService: OnrampUnknownStatusRecoveryService {
    func start() {
        guard observationTask == nil else { return }
        observationTask = runTask(in: self) { service in
            let stream = await service.unknownStatusRepository.recordsPublisher.values
            for await _ in stream {
                guard !Task.isCancelled else { return }
                service.runRecoveryPass()
            }
        }
        tickTask = runTask(in: self) { service in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(OnrampUnknownStatusRepositoryConstants.recoveryThrottle))
                guard !Task.isCancelled else { return }
                service.runRecoveryPass()
            }
        }
    }

    func cancel() {
        observationTask?.cancel()
        observationTask = nil
        tickTask?.cancel()
        tickTask = nil
        recoveryTask?.cancel()
        recoveryTask = nil
    }
}
