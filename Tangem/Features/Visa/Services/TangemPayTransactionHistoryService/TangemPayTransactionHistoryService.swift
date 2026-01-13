//
//  TangemPayTransactionHistoryService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemVisa
import TangemFoundation
import TangemPay

typealias TangemPayTransactionRecord = TangemPayTransactionHistoryResponse.Transaction

final class TangemPayTransactionHistoryService {
    private let storage: ThreadSafeContainer<[TangemPayTransactionRecord]> = []
    private let apiService: TangemPayCustomerService
    private let mapper = TangemPayTransactionHistoryMapper()

    private let numberOfItemsOnPage: Int = 20
    private var reachEndOfHistoryList = false

    private let stateSubject = CurrentValueSubject<TransactionHistoryServiceState, Never>(.initial)
    private var historyReloadTask: Task<Void, Never>?

    init(apiService: TangemPayCustomerService) {
        self.apiService = apiService
    }
}

extension TangemPayTransactionHistoryService {
    var tangemPayTransactionHistoryState: AnyPublisher<TransactionsListView.State, Never> {
        stateSubject
            .withWeakCaptureOf(self)
            .map { service, state in
                switch state {
                case .initial:
                    return .loading

                case .loading:
                    let transactions = service.storage.read()
                    return transactions.isEmpty
                        ? .loading
                        : .loaded(service.mapper.formatTransactions(transactions))

                case .failedToLoad(let error):
                    return .error(error)

                case .loaded:
                    let transactions = service.storage.read()
                    return .loaded(service.mapper.formatTransactions(transactions))
                }
            }
            .eraseToAnyPublisher()
    }

    func fetchNextTransactionHistoryPage() -> FetchMore? {
        guard !reachEndOfHistoryList else {
            return nil
        }

        return FetchMore { [weak self] in
            self?.loadNextHistoryPage()
        }
    }

    @discardableResult
    func reloadHistory() -> Task<Void, Never> {
        if let historyReloadTask {
            return historyReloadTask
        }

        let task = runTask { [weak self] in
            await self?.reloadHistory()
            self?.historyReloadTask = nil
        }

        historyReloadTask = task

        return task
    }

    func getTransaction(id: String) -> TangemPayTransactionRecord? {
        storage.read().first(where: { $0.id == id })
    }
}

private extension TangemPayTransactionHistoryService {
    func reloadHistory() async {
        stateSubject.send(.loading)
        let firstItemsInStorage = Array(storage.read().prefix(numberOfItemsOnPage))

        do {
            let itemsOnServer = try await apiService.getTransactionHistory(limit: numberOfItemsOnPage, cursor: nil).transactions
            if firstItemsInStorage == itemsOnServer {
                stateSubject.send(.loaded)
                return
            }

            storage.mutate { $0.removeAll() }
            reachEndOfHistoryList = itemsOnServer.count % numberOfItemsOnPage != 0
            saveRecordsInStorage(records: itemsOnServer)
            stateSubject.send(.loaded)
        } catch {
            stateSubject.send(.failedToLoad(error))
        }
    }

    func loadNextHistoryPage() {
        guard historyReloadTask == nil else {
            return
        }

        historyReloadTask = Task { [weak self] in
            await self?.loadNextPage()
            self?.historyReloadTask = nil
        }
    }

    func loadNextPage() async {
        if reachEndOfHistoryList {
            return
        }

        stateSubject.send(.loading)

        let cursor = storage.read().last?.id
        do {
            let loadedRecords = try await apiService.getTransactionHistory(limit: numberOfItemsOnPage, cursor: cursor).transactions
            reachEndOfHistoryList = loadedRecords.count != numberOfItemsOnPage
            saveRecordsInStorage(records: loadedRecords)
            stateSubject.send(.loaded)
        } catch {
            stateSubject.send(.failedToLoad(error))
        }
    }

    func saveRecordsInStorage(records: [TangemPayTransactionHistoryResponse.Transaction]) {
        storage.mutate { value in
            value.append(contentsOf: records)
        }
    }
}
