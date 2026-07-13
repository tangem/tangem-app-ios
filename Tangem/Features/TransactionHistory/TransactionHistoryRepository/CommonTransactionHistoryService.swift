//
//  CommonTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import Combine
import TangemFoundation

class CommonTransactionHistoryService {
    private let tokenItem: TokenItem
    private let address: String

    private let transactionHistoryProvider: BlockchainSdk.TransactionHistoryProvider

    private var _state = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private let pageSize: Int = 100
    private var cancellable: AnyCancellable?
    private let storage = TransactionRecordsStorage()

    init(
        tokenItem: TokenItem,
        address: String,
        transactionHistoryProvider: BlockchainSdk.TransactionHistoryProvider
    ) {
        self.tokenItem = tokenItem
        self.address = address
        self.transactionHistoryProvider = transactionHistoryProvider
    }
}

// MARK: - TransactionHistoryService

extension CommonTransactionHistoryService: TransactionHistoryService {
    var state: TransactionHistoryServiceState {
        _state.value
    }

    var statePublisher: AnyPublisher<TransactionHistoryServiceState, Never> {
        _state.eraseToAnyPublisher()
    }

    var items: [TransactionRecord] {
        get async { await storage.records }
    }

    var canFetchHistory: Bool {
        transactionHistoryProvider.canFetchHistory
    }

    func clearHistory() async {
        cancellable = nil
        transactionHistoryProvider.reset()
        await cleanStorage()
        AppLogger.info(self, "was reset")
    }

    func update() -> AnyPublisher<Void, Never> {
        Deferred {
            Future { [weak self] promise in
                self?.fetch(result: promise)
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension CommonTransactionHistoryService {
    func fetch(result: @escaping (Result<Void, Never>) -> Void) {
        cancellable = nil

        guard canFetchHistory else {
            AppLogger.info(self, "reached the end of list")
            result(.success(()))
            return
        }

        AppLogger.info(self, "start loading")
        _state.send(.loading)

        let request = TransactionHistory.Request(address: address, amountType: tokenItem.amountType, limit: pageSize)

        cancellable = transactionHistoryProvider
            .loadTransactionHistory(request: request)
            .handleEvents(receiveCancel: { [weak self] in
                // Resolves conflicting requests for tracking history from different consumers so as not to lose output from the update process
                AppLogger.info(self, "canceled")
                result(.success(()))
            })
            .withWeakCaptureOf(self)
            .asyncMap { service, response in
                await service.addToStorage(records: response.records)
            }
            .receiveCompletion { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?._state.send(.failedToLoad(error))
                    AppLogger.error(self, error: error)
                    result(.success(()))
                case .finished:
                    self?._state.send(.loaded)
                    AppLogger.info(self, "loaded")
                    result(.success(()))
                }
            }
    }

    func cleanStorage() async {
        await storage.clear()
    }

    func addToStorage(records: [TransactionRecord]) async {
        await storage.merge(records)
    }
}

// MARK: - Auxiliary types

private extension CommonTransactionHistoryService {
    actor TransactionRecordsStorage {
        private(set) var records: [TransactionRecord] = []

        func clear() {
            records.removeAll()
        }

        func merge(_ newRecords: [TransactionRecord]) {
            records.appendMerging(newRecords)
        }
    }
}

// MARK: - CustomStringConvertible

extension CommonTransactionHistoryService: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": tokenItem.name,
                "type": tokenItem.isToken ? "Token" : "Coin",
                "request": transactionHistoryProvider.description,
            ]
        )
    }
}
